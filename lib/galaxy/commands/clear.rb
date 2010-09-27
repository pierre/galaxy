module Galaxy
    module Commands
        class ClearCommand < Command
            register_command "clear"
            changes_agent_state

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                agent.proxy.clear!
            end

            def self.help
                return <<-HELP
#{name}
        
        Stop and clear the active software deployment on the selected hosts
                HELP
            end
        end
    end
end
