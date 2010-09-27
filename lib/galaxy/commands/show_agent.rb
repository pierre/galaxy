module Galaxy
    module Commands
        class ShowAgentCommand < Command
            register_command "show-agent"

            def execute agents
                report.start
                agents.sort_by { |agent| agent.host }.each do |agent|
                    report.record_result agent
                end
                report.finish
            end

            def report_class
                Galaxy::Client::AgentStatusReport
            end

            def self.help
                return <<-HELP
#{name}
        
        Show metadata about the selected Galaxy agents
                HELP
            end
        end
    end
end
