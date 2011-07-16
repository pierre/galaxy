module Galaxy
    module Agent
        class Configuration
            attr_reader :options

            # Precedence of options
            #   1/ command line
            #   2/ config file
            #   3/ environment variables
            #   4/ hardcoded values
            def initialize(cli_options={})
                @options = default_options
                @options.merge!(parse_file!)
                @options.merge!(cli_options)
                process_options
                @options
            end

            private

            def default_options
                {
                    :config => ENV["GALAXY_CONFIG"] || "/etc/galaxy.conf",
                    :agent_url => "druby://localhost:4441",
                    :agent_id => 'unset',
                    :agent_group => 'unknown',
                    :slot_environment => nil,
                    :verbose => false,
                    :log => ENV["GALAXY_LOG"] || "STDOUT",
                    :log_level => ENV["GALAXY_LOG_LEVEL"] || "INFO",
                    :pid_file => ENV["GALAXY_AGENT_PID_FILE"] || "/tmp/galaxy-agent.pid",
                    :user => nil,
                    :machine => Socket.gethostname,
                    :machine_file => ENV["GALAXY_MACHINE_FILE"] || nil,
                    :console_url => ENV["GALAXY_CONSOLE"] || "druby://localhost:4442",
                    :repository => "/var/tmp/galaxy-agent-properties",
                    :binaries => "http://localhost:8000",
                    :deploy_dir => "/var/tmp/galaxy-agent-deploy",
                    :data_dir => "/var/tmp/galaxy-agent-data",
                    :announce_interval => 60,
                    :http_user => nil,
                    :http_password => nil,
                    :legacy => true
                }
            end

            # Sanity checks for the options - this is mainly for legacy reasons
            def process_options
                # Read the machine name from the machine file
                if !@options[:machine] && @options[:machine_file] && File.exists?(@option[:machine_file])
                    File.open machine_file, "r" do |f|
                        @options[:machine] = f.read.chomp
                    end
                end

                # Cleanup agent url - and default to drb
                @options[:agent_url] = "druby://#{@options[:agent_url]}" unless @options[:agent_url].match(/^https?:\/\//) || @options[:agent_url].match("^druby://")
                @options[:agent_url] = "#{@options[:agent_url]}:4441" unless @options[:agent_url].match ":[0-9]+$"

                # Cleanup console url
                @options[:console_url] = "http://" + @options[:console_url] unless @options[:console_url].match(/^https?:\/\//) || @options[:console_url].match("^druby://")
                @options[:console_url] += ":4442" unless @options[:console_url].match ":[0-9]+$"
            end

            # Parse the configuration file
            def parse_file!
                config_file = options[:config]
                return {} if config_file.nil? or config_file.empty? or !File.exists?(config_file)

                # Parse the file (we expect YAML)
                begin
                    return YAML.load(File.read(config_file))
                rescue
                    # Fall through to empty config hash
                    return {}
                end
            end
        end
    end
end