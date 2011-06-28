require 'fileutils'
require 'logger'
require 'ostruct'
require 'resolv'
require 'socket'
require 'stringio'
require 'yaml'

require 'galaxy/agent_remote_api'
require 'galaxy/config'
require 'galaxy/controller'
require 'galaxy/db'
require 'galaxy/deployer'
require 'galaxy/fetcher'
require 'galaxy/log'
require 'galaxy/properties'
require 'galaxy/repository'
require 'galaxy/software'
require 'galaxy/starter'
require 'galaxy/transport'
require 'galaxy/version'
require 'galaxy/versioning'
require 'galaxy/slotinfo'

module Galaxy
    class Agent
        # Agent configuration options
        attr_reader :options
        # Current deployment configuration
        attr_reader :config

        attr_accessor :starter, :fetcher, :deployer, :db, :slot_info

        # Methods exposed via DrB - these only manipulate the @config state and the logger
        attr_reader :logger
        include Galaxy::AgentRemoteApi

        def initialize(options)
            @options = options
            @slot_environment = load_slot_environment

            @logger = Galaxy::Log::Glogger.new(@options[:log])
            @logger.log.level = begin
                case @options[:log_level]
                    when "DEBUG"
                        Logger::DEBUG
                    when "INFO"
                        Logger::INFO
                    when "WARN"
                        Logger::WARN
                    when "ERROR"
                        Logger::ERROR
                end
            end

            @lock = OpenStruct.new(:owner => nil, :count => 0, :mutex => Mutex.new)

            # Set up announcements to the console
            @announcer = Galaxy::Transport.locate(@options[:console_url], @logger)

            # Create missing folders if they don't already exist.
            # This needs to be done here, so that in case that the agent changes the user to run as,
            # it is done as the new user, not as the old (root) user.
            FileUtils.mkdir_p(@options[:deploy_dir]) unless File.exists? @options[:deploy_dir]
            FileUtils.mkdir_p(@options[:data_dir]) unless File.exists? @options[:data_dir]

            @prop_builder = Galaxy::Properties::Builder.new(@options[:repository], @options[:http_user], @options[:http_password], @logger)
            @repository = Galaxy::Repository.new(@options[:repository], @logger)
            @db = Galaxy::DB.new(@options[:data_dir])
            @slot_info = Galaxy::SlotInfo.new(@db, @options[:repository], @options[:binaries], @logger, @options[:machine],
                                              @options[:agent_id], @options[:agent_group], @slot_environment)
            @deployer = Galaxy::Deployer.new(@options[:repository], @options[:binaries], @options[:deploy_dir], @logger, @slot_info)
            @fetcher = Galaxy::Fetcher.new(@options[:binaries], @options[:http_user], @options[:http_password], @logger)
            @starter = Galaxy::Starter.new(@logger, @db)

            if RUBY_PLATFORM =~ /\w+-(\D+)/
                @os = $1
                @logger.debug "Detected OS: #{@os}"
            end

            current_deployment = current_deployment_number
            @config = read_config current_deployment

            # Make sure that the slot_info file is current.
            @slot_info.update @config.config_path, @deployer.core_base_for(current_deployment)

            Galaxy::Transport.publish @options[:agent_url], self, @logger
            announce
            sync_state!

            # Heartbeat to the gonsole
            @thread = Thread.start do
                loop do
                    sleep @options[:announce_interval]
                    announce
                end
            end
        end

        def sync_state!
            lock

            begin
                if @config
                    # Get the status from the core
                    status = @starter.status @config.core_base
                    @config.state = status
                    write_config current_deployment_number, @config
                end
            ensure
                unlock
            end
        end

        def status
            OpenStruct.new(
                :agent_id => @options[:agent_id],
                :agent_group => @options[:agent_group],
                :url => @options[:agent_url],
                :os => @os,
                :machine => @options[:machine],
                :core_type => config.core_type,
                :config_path => config.config_path,
                :build => config.build,
                :status => @starter.status(config.core_base),
                :last_start_time => config.last_start_time,
                :agent_status => 'online',
                :galaxy_version => Galaxy::Version,
                :slot_info => @slot_info.get_slot_info
            )
        end

        def announce
            begin
                res = @announcer.announce status
                return res
            rescue Exception => e
                error_reason = "Unable to communicate with console, #{e.message}"
                @logger.warn "Unable to communicate with console, #{e.message}"
                @logger.warn e
            end
        end

        def read_config deployment_number
            config = nil
            deployment_number = deployment_number.to_s
            data = @db[deployment_number]
            unless data.nil?
                begin
                    config = YAML.load data
                    unless config.is_a? OpenStruct
                        config = nil
                        raise "Expecting serialized OpenStruct"
                    end
                rescue Exception => e
                    @logger.warn "Error reading deployment descriptor: #{@db.file_for(deployment_number)}: #{e}"
                end
            end
            config ||= OpenStruct.new
            # Ensure autostart=true for pre-2.5 deployments
            if config.auto_start.nil?
                config.auto_start = true
            end
            config
        end

        def write_config deployment_number, config
            deployment_number = deployment_number.to_s
            @db[deployment_number] = YAML.dump config
        end

        def current_deployment_number
            @db['deployment'] ||= "0"
            @db['deployment'].to_i
        end

        def current_deployment_number= deployment_number
            deployment_number = deployment_number.to_s
            @db['deployment'] = deployment_number
            @config = read_config deployment_number
        end

        # Stop the agent
        def shutdown
            @starter.stop! config.core_base if config
            @thread.kill
            Galaxy::Transport.unpublish @options[:agent_url]
        end

        # Wait for the agent to finish
        def join
            @thread.join
        end

        # Main entry point from the command line clent
        def Agent.start(options)
            Agent.new(options)
        end

        private

        #
        # Loads the slot environment file for this
        # deployment. This is stored alongside the
        # actual slot data for later use.
        #
        def load_slot_environment
            unless @options[:slot_environment].nil?
                begin
                    File.open(@options[:slot_environment], "r") do |f|
                        return YAML.load(f.read)
                    end
                rescue Errno::ENOENT
                end
            end
            {}
        end

        def lock
            @lock.mutex.synchronize do
                raise "Agent is locked performing another operation" unless @lock.owner.nil? || @lock.owner == Thread.current

                @lock.owner = Thread.current if @lock.owner.nil?

                @logger.debug "Locking from #{caller[2]}" if @lock.count == 0
                @lock.count += 1
            end
        end

        def unlock
            @lock.mutex.synchronize do
                raise "Lock not owned by current thread" unless @lock.owner.nil? || @lock.owner == Thread.current
                @lock.count -= 1
                @lock.owner = nil if @lock.count == 0

                @logger.debug "Unlocking from #{caller[2]}" if @lock.count == 0
            end
        end
    end
end
