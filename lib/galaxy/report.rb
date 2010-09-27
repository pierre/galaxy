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
                STDOUT.tty? ? "%-20s %-8s %-10s\n" : "%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.host),
                    format_field(result.agent_status),
                    format_field(result.galaxy_version),
                ]
            end
        end

        class SoftwareDeploymentReport < Report
            private

            def format_string
                STDOUT.tty? ? "%-20s %-45s %-10s %-15s %-20s %-20s %-15s %-8s\n" : "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.host),
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
                STDOUT.tty? ? "%-20s %-45s %-10s %-15s %-20s %-14s\n" : "%s\t%s\t%s\t%s\t%s\t%s\n"
            end

            def format_field field
                field ? field : '-'
            end

            def format_result result
                [
                    format_field(result.host),
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
                STDOUT.tty? ? "%-45s %-10s %-15s %-20s %s\n" : "%s\t%s\t%s\t%s\t%s\n"
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
                host, output = format_result(result)
                output.split("\n").each { |line| @buffer += sprintf(format_string, host, line) }
            end

            private

            def format_string
                "%-20s %s\n"
            end

            def format_result result
                status, output = result
                return "#{status.host}:", output
            end
        end
    end
end
