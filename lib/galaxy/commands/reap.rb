module Galaxy
    module Commands
        class ReapCommand < Command
            register_command "reap"
            changes_console_state

            def execute agents
                report.start
                agents.sort_by { |agent| agent.agent_id }.each do |agent|
                    reaped = @options[:console].reap(agent.agent_id, agent.agent_group)
                    report.record_result("#{agent.agent_id}/#{agent.agent_group} - reap #{reaped.nil? ? 'failed' : 'succeeded'}")
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
