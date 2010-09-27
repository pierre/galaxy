module Galaxy
    module Commands
        class ShowConsoleCommand < Command
            register_command "show-console"

            def execute agents
                report.start
                report.record_result @options[:console]
                report.finish
            end

            def report_class
                Galaxy::Client::ConsoleStatusReport
            end

            def self.help
                return <<-HELP
#{name}

        Show metadata about the selected Galaxy console
                HELP
            end
        end
    end
end
