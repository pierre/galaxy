module Galaxy
    module Versioning
        class StrictVersioningPolicy
            def self.assignment_allowed? current_config, requested_config
                if current_config.environment == requested_config.environment and current_config.type == requested_config.type
                    return current_config.version != requested_config.version
                end
                true
            end
        end

        class RelaxedVersioningPolicy
            def self.assignment_allowed? current_config, requested_config
                true
            end
        end
    end
end
