module Galaxy
    module Commands
        class CleanupCommand < Command
            register_command "cleanup"

            def execute_for_agent agent
                agent.proxy.cleanup!
            end

            def self.help
                return <<-HELP
#{name}

        Remove all deployments up to the current and last one, for rollback.
                HELP
            end
        end
    end
end
