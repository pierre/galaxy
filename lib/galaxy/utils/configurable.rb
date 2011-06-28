module Galaxy
    module Utils
        module Configurable
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