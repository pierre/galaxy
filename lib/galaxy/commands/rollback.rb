module Galaxy
    module Commands
        class RollbackCommand < Command
            register_command "rollback"
            changes_agent_state

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                agent.proxy.rollback!
            end

            def self.help
                return <<-HELP
#{name}
      
        Stop and rollback software to the previously deployed version
                HELP
            end
        end
    end
end
