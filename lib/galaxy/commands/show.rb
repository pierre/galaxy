module Galaxy
    module Commands
        class ShowCommand < Command
            register_command "show"

            def execute agents
                report.start
                agents.sort_by { |agent| agent.id }.each do |agent|
                    report.record_result agent
                end
                report.finish
            end

            def self.help
                return <<-HELP
#{name}
        
        Show software deployments on the selected hosts

        Examples:
        
        - Show all hosts:
            galaxy show

        - Show unassigned hosts:
            galaxy -s empty show

        - Show assigned hosts:
            galaxy -s taken show

        - Show a specific host:
            galaxy -i foo.bar.com show

        - Show all widgets:
            galaxy -t widget show
                HELP
            end
        end
    end
end
