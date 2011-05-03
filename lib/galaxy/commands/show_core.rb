module Galaxy
    module Commands
        class ShowCoreCommand < Command
            register_command "show-core"

            def execute agents
                report.start
                agents.sort_by { |agent| agent.id }.each do |agent|
                    report.record_result agent
                end
                report.finish
            end

            def report_class
                Galaxy::Client::CoreStatusReport
            end

            def self.help
                return <<-HELP
#{name}

        Show core status (last start time, ...) on the selected hosts
        See "galaxy show -h" for help and examples on flags usage
                HELP
            end
        end
    end
end
