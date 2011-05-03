require 'logger'
require 'yaml'

module Galaxy
    class Controller
        def initialize db, core_base, config_path, repository_base, binaries_base, log, machine, agent_id, agent_group, slot_environment = nil
            @db = db
            @core_base = core_base
            @config_path = config_path
            @repository_base = repository_base
            @binaries_base = binaries_base
            @machine = machine
            @agent_id = agent_id
            @agent_group = agent_group
            @slot_environment = slot_environment

            script = File.join(@core_base, "bin", "control")
            if File.exists? script
                @script = File.executable?(script) ? script : "/bin/sh #{script}"
            else
                raise ControllerNotFoundException.new
            end
            @log = log
        end

        def perform! command, args = ''
            @log.info "Invoking control script: #{@script} #{command} #{args}"

            slot_info = OpenStruct.new(:base => @core_base,
                                        :binaries => @binaries_base,
                                        :config_path => @config_path,
                                        :repository => @repository_base,
                                        :machine => @machine,
                                        :agent_id => @agent_id,
                                        :agent_group => @agent_group,
                                        :env => @slot_environment)

            @db['slot_info'] = YAML.dump slot_info

            begin
                output = `#{@script} --slot-info #{@db.file_for('slot_info')} #{command} #{args} 2>&1`
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
