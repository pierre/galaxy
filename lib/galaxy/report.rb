module Galaxy
    module Client
        class Report
            def initialize
                @buffer = ""
            end

            def start
            end

            def record_result result
                @buffer += sprintf(format_string, * format_result(result))
            end

            def finish
                @buffer.length > 0 ? @buffer : nil
            end

            private

            def format_string
                "%s\n"
            end

            def format_result result
                [result]
            end
        end

        class ConsoleStatusReport < Report
            private

            def format_string
                "%s\t%s\t%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.drb_url),
                    format_field(result.http_url),
                    format_field(result.host),
                    format_field(result.env),
                    format_field(result.ping_interval),
                ]
            end
        end

        class AgentStatusReport < Report
            private

            def format_string
                STDOUT.tty? ? "%-10s %-10s %-8s %-10s\n" : "%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.agent_id),
                    format_field(result.agent_group),
                    format_field(result.agent_status),
                    format_field(result.galaxy_version),
                ]
            end
        end

        class SoftwareDeploymentReport < Report
            private

            def format_string
                STDOUT.tty? ? "%-10s %-10s %-45s %-10s %-30s %-30s %-20s %-15s %-8s\n" : "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.agent_id),
                    format_field(result.agent_group),
                    format_field(result.config_path),
                    format_field(result.status),
                    format_field(result.build),
                    format_field(result.core_type),
                    format_field(result.machine),
                    format_field(result.ip),
                    format_field(result.agent_status),
                ]
            end
        end

        class CoreStatusReport < Report
            private

            def format_string
                STDOUT.tty? ? "%-10s %-10s %-45s %-10s %-30s %-30s %-14s\n" : "%s\t%s\t%s\t%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.agent_id),
                    format_field(result.agent_group),
                    format_field(result.config_path),
                    format_field(result.status),
                    format_field(result.build),
                    format_field(result.core_type),
                    format_field(result.last_start_time),
                ]
            end
        end

        class LocalSoftwareDeploymentReport < Report
            private

            def format_string
                STDOUT.tty? ? "%-45s %-10s %-30s %-30s %s\n" : "%s\t%s\t%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.config_path),
                    format_field(result.status),
                    format_field(result.build),
                    format_field(result.core_type),
                    "autostart=#{result.auto_start}",
                ]
            end
        end

        class CommandOutputReport < Report
            def initialize
                super
                @software_deployment_report = SoftwareDeploymentReport.new
            end

            def record_result result
                @software_deployment_report.record_result(result[0])
                agent_id, agent_group, output = format_result(result)
                output.split("\n").each { |line| @buffer += sprintf(format_string, agent_id, agent_group, line) }
            end

            private

            def format_string
                "%-10s %-10s %s\n"
            end

            def format_result result
                status, output = result
                return status.agent_id, status.agent_group, output
            end
        end
    end
end
