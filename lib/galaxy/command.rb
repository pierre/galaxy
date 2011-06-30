require 'galaxy/agent_utils'
require 'galaxy/parallelize'
require 'galaxy/report'

module Galaxy
    module Commands
        @@commands = {}

        def self.register_command command_name, command_class
            @@commands[command_name] = command_class
        end

        def self.[] command_name
            @@commands[command_name]
        end

        def self.each
            @@commands.keys.sort.each { |command| yield command }
        end

        class Command
            class << self
                attr_reader :name
            end

            def self.register_command name
                @name = name
                Galaxy::Commands.register_command name, self
            end

            def self.changes_agent_state
                define_method("changes_agent_state") do
                    true
                end
            end

            def self.changes_console_state
                define_method("changes_console_state") do
                    true
                end
            end

            def initialize args = [], options = {}
                @args = args
                @options = options
                @options[:thread_count] ||= 1
            end

            def changes_agent_state
                false
            end

            def changes_console_state
                false
            end

            def select_agents filter
                normalized_filter = normalize_filter(filter)
                @options[:console].agents(normalized_filter)
            end

            def normalize_filter filter
                filter = default_filter if filter.empty?
                filter
            end

            def default_filter
                {:set => :all}
            end

            def execute agents
                report.start
                error_report.start
                agents.parallelize(@options[:thread_count]) do |agent|
                    begin
                        unless agent.agent_status == 'online'
                            raise "Agent is not online"
                        end
                        Galaxy::AgentUtils::ping_agent(agent)
                        result = execute_for_agent(agent)
                        report.record_result result
                    rescue TimeoutError
                        error_report.record_result "Error: Timed out communicating with agent #{agent.agent_id}/#{agent.agent_group}"
                    rescue Exception => e
                        error_report.record_result "Error: #{agent.agent_id}/#{agent.agent_group}: #{e}"
                    end
                end
                return report.finish, error_report.finish
            end

            def report
                @report ||= report_class.new
            end

            def report_class
                Galaxy::Client::SoftwareDeploymentReport
            end

            def error_report
                @error_report ||= Galaxy::Client::Report.new
            end
        end
    end
end

# load and register all commands
Dir.entries("#{File.join(File.dirname(__FILE__))}/commands").each do |entry|
    if entry =~ /\.rb$/
        require "galaxy/commands/#{File.basename(entry, '.rb')}"
    end
end
