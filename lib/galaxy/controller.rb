require 'logger'
require 'yaml'

require 'galaxy/slotinfo'

module Galaxy
    class Controller
        def initialize slot_info, core_base, log
            @slot_info = slot_info
            @core_base = core_base
            @log = log

            script = File.join(@core_base, "bin", "control")
            if File.exists? script
                @script = File.executable?(script) ? script : "/bin/sh #{script}"
            else
                raise ControllerNotFoundException.new
            end
        end

        def perform! command, args = ''
            exec_script="#{@script} --slot-info #{@slot_info.get_file_name} #{command} #{args}"
            @log.info "Invoking control script: #{exec_script}"

            begin
                output = `#{exec_script} 2>&1`
            rescue Exception => e
                raise ControllerFailureException.new(command, e)
            end

            rv = $?.exitstatus

            case rv
                when 0
                    output
                when 1
                    raise CommandFailedException.new(command, output)
                when 2
                    raise UnrecognizedCommandException.new(command, output)
                else
                    raise UnrecognizedResponseCodeException.new(rv, command, output)
            end
        end

        class ControllerException < RuntimeError;
        end

        class ControllerNotFoundException < ControllerException
            def initialize
                super "No control script available"
            end
        end

        class ControllerFailureException < ControllerException
            def initialize command, exception
                super "Unexpected exception executing command '#{command}': #{exception}"
            end
        end

        class CommandFailedException < ControllerException
            def initialize command, output
                message = "Command failed: #{command}"
                message += ": #{output}" unless output.empty?
                super message
            end
        end

        class UnrecognizedCommandException < ControllerException
            def initialize command, output
                message = "Unrecognized command: #{command}"
                message += ": #{output}" unless output.empty?
                super message
            end
        end

        class UnrecognizedResponseCodeException < ControllerException
            def initialize code, command, output
                message = "Unrecognized response code #{code} for command #{command}"
                message += ": #{output}" unless output.empty?
                super message
            end
        end
    end
end
