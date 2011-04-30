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
require 'galaxy/events'
require 'galaxy/fetcher'
require 'galaxy/log'
require 'galaxy/properties'
require 'galaxy/repository'
require 'galaxy/software'
require 'galaxy/starter'
require 'galaxy/transport'
require 'galaxy/version'
require 'galaxy/versioning'

module Galaxy
    class Agent
        attr_reader :host, :machine, :config, :locked, :logger, :gonsole_url
        attr_accessor :starter, :fetcher, :deployer, :db

        include Galaxy::AgentRemoteApi

        def initialize host, url, machine, announcements_url, repository_base, deploy_dir,
            data_dir, binaries_base, http_user, http_password, log, log_level, announce_interval, event_listener
            @drb_url = url
            @host = host
            @machine = machine
            @http_user = http_user
            @http_password = http_password
            @ip = Resolv.getaddress(@host)

            # Setup the logger and the event dispatcher (HDFS) if needed
            @logger = Galaxy::Log::Glogger.new log, event_listener, announcements_url, @ip
            @logger.log.level = log_level

            @lock = OpenStruct.new(:owner => nil, :count => 0, :mutex => Mutex.new)

            # set up announcements
            @gonsole_url = announcements_url
            @announcer = Galaxy::Transport.locate announcements_url, @logger

            # Setup event listener
            @event_dispatcher = Galaxy::GalaxyEventSender.new(event_listener, @gonsole_url, @ip, @logger)

            @announce_interval = announce_interval
            @prop_builder = Galaxy::Properties::Builder.new repository_base, @http_user, @http_password, @logger
            @repository = Galaxy::Repository.new repository_base, @logger
            @deployer = Galaxy::Deployer.new deploy_dir, @logger
            @fetcher = Galaxy::Fetcher.new binaries_base, @http_user, @http_password, @logger
            @starter = Galaxy::Starter.new @logger
            @db = Galaxy::DB.new data_dir
            @repository_base = repository_base
            @binaries_base = binaries_base

            if RUBY_PLATFORM =~ /\w+-(\D+)/
                @os = $1
                @logger.debug "Detected OS: #{@os}"
            end

            @logger.debug "Detected machine: #{@machine}"

            @config = read_config current_deployment_number

            Galaxy::Transport.publish url, self
            announce
            sync_state!

            @thread = Thread.start do
                loop do
                    sleep @announce_interval
                    announce
                end
            end
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

        def status
            OpenStruct.new(
                :host => @host,
                :ip => @ip,
                :url => @drb_url,
                :os => @os,
                :machine => @machine,
                :core_type => config.core_type,
                :config_path => config.config_path,
                :build => config.build,
                :status => @starter.status(config.core_base),
                :last_start_time => config.last_start_time,
                :agent_status => 'online',
                :galaxy_version => Galaxy::Version
            )
        end

        def announce
            begin
                res = @announcer.announce status
                @event_dispatcher.dispatch_announce_success_event status
                return res
            rescue Exception => e
                error_reason = "Unable to communicate with console, #{e.message}"
                @logger.warn "Unable to communicate with console, #{e.message}"
                @logger.warn e
                @event_dispatcher.dispatch_announce_error_event error_reason
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

        # private
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

        # Stop the agent
        def shutdown
            @starter.stop! config.core_base if config
            @thread.kill
            Galaxy::Transport.unpublish @drb_url
        end

        # Wait for the agent to finish
        def join
            @thread.join
        end

        # args: host => IP/Name to uniquely identify this agent
        #     console => hostname of the console
        #     repository => base of url to repository
        #     binaries => base of url=l to binary repository
        #     deploy_dir => /path/to/deployment
        #     data_dir => /path/to/agent/data/storage
        #     log => /path/to/log || STDOUT || STDERR || SYSLOG
        #     url => url to listen on
        #     event_listener => url of the event listener
        def Agent.start args
            host_url = args[:host] || "localhost"
            host_url = "druby://#{host_url}" unless host_url.match("^http://") || host_url.match("^druby://") # defaults to drb
            host_url = "#{host_url}:4441" unless host_url.match ":[0-9]+$"

            # default console to http/4442 unless specified
            console_url = args[:console] || "localhost"
            console_url = "http://" + console_url unless console_url.match("^http://") || console_url.match("^druby://")
            console_url += ":4442" unless console_url.match ":[0-9]+$"

            # need host as simple name without protocol or port
            host = args[:host] || "localhost"
            host = host.sub(/^http:\/\//, "")
            host = host.sub(/^druby:\/\//, "")
            host = host.sub(/:[0-9]+$/, "")

            if args[:machine]
                machine = args[:machine]
            else
                machine_file = args[:machine_file] || Galaxy::Config::DEFAULT_MACHINE_FILE
                if File.exists? machine_file
                    File.open machine_file, "r" do |f|
                        machine = f.read.chomp
                    end
                else
                    machine = Socket.gethostname
                end
            end

            agent = Agent.new host,
                              host_url,
                              machine,
                              console_url,
                              args[:repository] || "/tmp/galaxy-agent-properties",
                              args[:deploy_dir] || "/tmp/galaxy-agent-deploy",
                              args[:data_dir] || "/tmp/galaxy-agent-data",
                              args[:binaries] || "http://localhost:8000",
                              args[:http_user],
                              args[:http_password],
                              args[:log] || "STDOUT",
                              args[:log_level] || Logger::INFO,
                              args[:announce_interval] || 60,
                              args[:event_listener]

            agent
        end

        private :initialize, :sync_state!, :config
    end

end
