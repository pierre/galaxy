require 'logger'
require 'socket'
require 'galaxy/host'

module Galaxy
    module Config
        DEFAULT_HOST = ENV["GALAXY_HOST"] || "localhost"
        DEFAULT_LOG = ENV["GALAXY_LOG"] || "SYSLOG"
        DEFAULT_LOG_LEVEL = ENV["GALAXY_LOG_LEVEL"] || "INFO"
        DEFAULT_MACHINE_FILE = ENV["GALAXY_MACHINE_FILE"] || ""
        DEFAULT_AGENT_PID_FILE = ENV["GALAXY_AGENT_PID_FILE"] || "/tmp/galaxy-agent.pid"
        DEFAULT_CONSOLE_PID_FILE = ENV["GALAXY_CONSOLE_PID_FILE"] || "/tmp/galaxy-console.pid"

        DEFAULT_PING_INTERVAL = 60

        def read_config_file config_file
            config_file = config_file || ENV['GALAXY_CONFIG']
            unless config_file.nil? or config_file.empty?
                msg = "Cannot find configuration file: #{config_file}"
                unless File.exist?(config_file)
                    # Log exception to syslog
                    syslog_log msg
                    raise msg
                end
            end
            config_files = [config_file, '/etc/galaxy.conf', '/usr/local/etc/galaxy.conf'].compact
            config_files.each do |file|
                begin
                    File.open file, "r" do |f|
                        return YAML.load(f.read)
                    end
                rescue Errno::ENOENT
                end
            end
            # Fall through to empty config hash
            return {}
        end

        def set_machine machine_from_file
            @machine ||= @config.machine || machine_from_file
        end

        def set_pid_file pid_file_from_file
            @pid_file ||= @config.pid_file || pid_file_from_file
        end

        def set_user user_from_file
            @user ||= @config.user || user_from_file || nil
        end

        def set_verbose verbose_from_file
            @verbose ||= @config.verbose || verbose_from_file
        end

        def set_log log_from_file
            @log ||= @config.log || log_from_file || DEFAULT_LOG
            begin
                # Check if we can log to it
                test_logger = Galaxy::Log::Glogger.new(@log)
                # Make sure to reap file descriptors (except STDOUT/STDERR/SYSLOG)
                test_logger.close unless @log == "STDOUT" or @log == "STDERR" or @log == "SYSLOG"
            rescue
                # Log exception to syslog
                syslog_log $!
                raise $!
            end

            return @log
        end

        def set_log_level log_level_from_file
            @log_level ||= begin
                log_level = @config.log_level || log_level_from_file || DEFAULT_LOG_LEVEL
                case log_level
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
        end

        def guess key
            val = self.send key
            puts "    --#{correct key} #{val}" if @config.verbose
            val
        end

        def syslog_log e
            Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS) { |s| s.warning e }
        end

        module_function :read_config_file, :set_machine, :set_pid_file, :set_verbose,
                        :set_log, :set_log_level, :set_user, :guess
    end

    class AgentConfigurator
        include Config

        def initialize config
            @config = config
            @config_from_file = read_config_file(config.config_file)
        end

        # This is a gross hack, that should die rather sooner than later -- hps
        def correct key
            case key
                # Agent
                when :agent_url
                    "agent-url"
                when :agent_id
                    "identifier"
                when :agent_group
                    "group"
                when :machine_file
                    "machine-file"
                when :deploy_dir
                    "deploy-to"
                when :data_dir
                    "data-dir"
                when :announce_interval
                    "announce-interval"
                when :http_user
                    "http-user"
                when :http_password
                    "http-password"

                # Shared opts
                when :log_level
                    "log-level"
                when :config_file
                    "config"
                else
                    key
            end
        end

        def configure
            puts "startup configuration" if @config.verbose
            {
                :agent_url => guess(:agent_url),
                :machine => guess(:machine),
                :agent_id => guess(:agent_id),
                :agent_group => guess(:agent_group),
                :console => guess(:console),
                :repository => guess(:repository),
                :binaries => guess(:binaries),
                :deploy_dir => guess(:deploy_dir),
                :verbose => guess(:verbose),
                :data_dir => guess(:data_dir),
                :log => guess(:log),
                :log_level => guess(:log_level),
                :pid_file => guess(:pid_file),
                :user => guess(:user),
                :announce_interval => guess(:announce_interval),
                :http_user => guess(:http_user),
                :http_password => guess(:http_password),
            }
        end

        def agent_url
            @agent_url ||= @config.agent_url || @config_from_file['galaxy.agent.agent_url']
        end

        # Identifier for this agent, will be reported in the gonsole output
        def agent_id
          @agent_id ||= @config.agent_id || @config_from_file['galaxy.agent.agent_id'] || 'unset'
        end

        # Group for this agent, will be reported in the gonsole output
        def agent_group
            @agent_group ||= @config.agent_group ||  @config_from_file['galaxy.agent.agent_group'] || 'unknown'
        end

        def verbose
            set_verbose @config_from_file['galaxy.agent.verbose']
        end

        def log
            set_log @config_from_file['galaxy.agent.log']
        end

        def log_level
            set_log_level @config_from_file['galaxy.agent.log-level']
        end

        def pid_file
            set_pid_file @config_from_file['galaxy.agent.pid-file'] || DEFAULT_AGENT_PID_FILE
        end

        def user
            set_user @config_from_file['galaxy.agent.user']
        end

        def machine
            set_machine @config_from_file['galaxy.agent.machine']
        end

        def console
            @console ||= @config.console || @config_from_file['galaxy.agent.console']
        end

        def repository
            @repository ||= @config.repository || @config_from_file['galaxy.agent.config-root']
        end

        def binaries
            @binaries ||= @config.binaries || @config_from_file['galaxy.agent.binaries-root']
        end

        def deploy_dir
            @deploy_dir ||= @config.deploy_dir || @config_from_file['galaxy.agent.deploy-dir'] || "#{HostUtils.avail_path}/galaxy-agent/deploy"
            @deploy_dir
        end

        def data_dir
            @data_dir ||= @config.data_dir || @config_from_file['galaxy.agent.data-dir'] || "#{HostUtils.avail_path}/galaxy-agent/data"
            @data_dir
        end

        def announce_interval
            @announce_interval ||= @config.announce_interval || @config_from_file['galaxy.agent.announce-interval'] || 60
            @announce_interval = @announce_interval.to_i
        end

        def http_user
            @http_user ||= @config.http_user || @config_from_file['galaxy.agent.http_user']
        end

        def http_password
            @http_password ||= @config.http_password || @config_from_file['galaxy.agent.http_password']
        end
    end

    class ConsoleConfigurator
        include Config

        def initialize config
            @config = config
            @config_from_file = read_config_file(config.config_file)
        end

        def correct key
            case key
                # Console
                when :announcement_url
                    "announcement-url"
                when :ping_interval
                    "ping-interval"
                when :console_proxied_url
                    "console-proxied-url"
                when :console_log
                    "console-log"

                # Shared opts
                when :log_level
                    "log-level"
                when :config_file
                    "config"
                else
                    key
            end
        end

        def configure
            puts "startup configuration" if @config.verbose
            {
                :environment => guess(:environment),
                :verbose => guess(:verbose),
                :log => guess(:log),
                :log_level => guess(:log_level),
                :pid_file => guess(:pid_file),
                :user => guess(:user),
                :host => guess(:host),
                :announcement_url => guess(:announcement_url),
                :ping_interval => guess(:ping_interval),
                :console_proxied_url => guess(:console_proxied_url),
            }
        end

        def console_proxied_url
            return @config.console_proxied_url
        end

        def verbose
            set_verbose @config_from_file['galaxy.agent.verbose']
        end

        def log
            set_log @config_from_file['galaxy.console.log']
        end

        def log_level
            set_log_level @config_from_file['galaxy.console.log-level']
        end

        def pid_file
            set_pid_file @config_from_file['galaxy.console.pid-file'] ||
                DEFAULT_CONSOLE_PID_FILE
        end

        def user
            set_user @config_from_file['galaxy.console.user']
        end

        def announcement_url
            @announcement_url ||= @config.announcement_url || @config_from_file['galaxy.console.announcement-url'] || "http://#{`hostname`.strip}"
        end

        def host
            @host ||= @config.host || @config_from_file['galaxy.console.host'] || begin
                Socket.gethostname rescue DEFAULT_HOST
            end
        end

        def ping_interval
            @ping_interval ||= @config.ping_interval || @config_from_file['galaxy.console.ping-interval'] || 60
            @ping_interval = @ping_interval.to_i
        end

        def environment
            @env ||= begin
                if @config.environment
                    @config.environment
                elsif @config_from_file['galaxy.console.environment']
                    @config_from_file['galaxy.console.environment']
                end
            end
        end
    end
end
