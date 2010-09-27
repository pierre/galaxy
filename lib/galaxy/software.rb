module Galaxy
    class SoftwareExecutable
        attr_accessor :type, :version

        def initalize type, version
            @type = type
            @version = version
        end
    end

    class SoftwareConfiguration
        attr_accessor :environment, :version, :type

        def initialize environment, version, type
            @environment = environment
            @version = version
            @type = type
        end

        def config_path
            "/#{environment}/#{version}/#{type}"
        end

        def self.new_from_config_path config_path
            # Using ! as regex delimiter since the config path contains / characters
            unless components = %r!^/([^/]+)/([^/]+)/(.*)$!.match(config_path)
                raise "Illegal config path '#{config_path}'"
            end
            environment, version, type = components[1], components[2], components[3]
            new environment, version, type
        end
    end

    class SoftwareDeployment
        attr_accessor :executable, :config, :running_state

        def initialize executable, config, running_state
            @executable = executable
            @config = config
            @running_state = running_state
        end
    end
end
