module Galaxy
    module Commands
        class StopCommand < Command
            register_command "stop"
            changes_agent_state

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                agent.proxy.stop!
            end

            def self.help
                return <<-HELP
#{name}

        Stop the deployed software on the selected hosts
                HELP
            end
        end
    end
end
