require 'galaxy/software'

module Galaxy
    module Commands
        class UpdateCommand < Command
            register_command "update"
            changes_agent_state

            def initialize args, options
                super
                @requested_version = args.first
                raise CommandLineError.new("Must specify version") unless @requested_version
                @versioning_policy = options[:versioning_policy]
                @build_version = options[:build_version]
            end

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                if agent.config_path.nil? or agent.config_path.empty?
                    raise "Cannot update unassigned agent"
                end
                current_config = Galaxy::SoftwareConfiguration.new_from_config_path(agent.config_path) # TODO - this should already be tracked
                requested_config = current_config.dup
                requested_config.version = @requested_version
                agent.proxy.become!(@build_version, requested_config.config_path, @versioning_policy)
            end

            def self.help
                return <<-HELP
#{name}  <version>
      
        Stop and update the software on the selected hosts to the specified version
                HELP
            end
        end
    end
end
