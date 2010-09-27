module Galaxy
    module Commands
        class RestartCommand < Command
            register_command "restart"
            changes_agent_state

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                agent.proxy.restart!
            end

            def self.help
                return <<-HELP
#{name}
      
        Restart the deployed software on the selected hosts
                HELP
            end
        end
    end
end
