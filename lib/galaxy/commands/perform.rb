module Galaxy
    module Commands
        class PerformCommand < Command
            register_command "perform"
            changes_agent_state

            def initialize args, options
                super

                @command = args.shift
                raise CommandLineError.new("<command> is missing") unless @command
                @args = args
            end

            def normalize_filter filter
                filter = super
                filter[:set] = :taken if filter[:set] == :all
                filter
            end

            def execute_for_agent agent
                agent.proxy.perform! @command, @args.join(' ')
            end

            def report_class
                Galaxy::Client::CommandOutputReport
            end

            def self.help
                return <<-HELP
#{name}

        galaxy perform <command> [args]

        Launch the control script (bin/control) with the indicated command on the selected hosts, optionally passing the provided arguments
                HELP
            end
        end
    end
end
