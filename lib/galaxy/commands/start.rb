module Galaxy
    module Commands
        class StartCommand < Command
            register_command "start"
            changes_agent_state

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                agent.proxy.start!
            end

            def self.help
                return <<-HELP
#{name}
      
        Start the deployed software on the selected hosts
                HELP
            end
        end
    end
end
