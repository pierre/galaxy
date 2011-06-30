module Galaxy
    module Commands
        class UpdateConfigCommand < Command
            register_command "update-config"
            changes_agent_state

            def initialize args, options
                super

                @requested_version = args.first
                raise CommandLineError.new("Must specify version") unless @requested_version

                @versioning_policy = options[:versioning_policy]
                @config_uri = @options[:config_uri]
                @binaries_uri = @options[:binaries_uri]
            end

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                if agent.config_path.nil? or agent.config_path.empty?
                    raise "Cannot update configuration of unassigned agent"
                end
                current_config = Galaxy::SoftwareConfiguration.new_from_config_path(agent.config_path) # TODO - this should already be tracked
                agent.proxy.update_config!(@requested_version, @config_uri, @binaries_uri, @versioning_policy)
            end

            def self.help
                return <<-HELP
#{name}  <version>
      
        Update the software configuration on the selected hosts to the specified version
        
        This does NOT redeploy or restart the software. If a restart is desired to activate the new configuration, it must be done separately.
                HELP
            end
        end
    end
end
