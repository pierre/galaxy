module Galaxy
    module Commands
        class ReapCommand < Command
            register_command "reap"
            changes_console_state

            def execute agents
                report.start
                agents.sort_by { |agent| agent.host }.each do |agent|
                    reaped = @options[:console].reap(agent.host)
                    report.record_result("#{agent.host} - reap #{reaped.nil? ? 'failed' : 'succeeded'}")
                end
                [report.finish, nil]
            end

            def report_class
                Galaxy::Client::Report
            end

            def self.help
                return <<-HELP
#{name}
        
        Delete stale announcements (from the console) for the selected hosts, without affecting agents
                HELP
            end
        end
    end
end
