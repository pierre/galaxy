require File.expand_path(File.join(Galaxy::Agent::BASE, 'host'))

module Galaxy::Agent
    class Starter

        RUNNING = "running"
        STOPPED = "stopped"
        UNKNOWN = "unknown"

        def initialize(log, slot_info_path=nil)
            @log = log
            @slot_info_path = slot_info_path
        end

        # Given a deployment_path, perform the action on the specified core
        [:start!, :restart!, :stop!, :status].each do |action|
            define_method action.to_s do |path|
                command = "#{launcher_path(path)} --slot-info #{@slot_info_path} #{action.to_s.chomp('!')}"

                @log.info "Running #{command}"
                output, return_code = HostUtils.system(command)
                @log.debug "#{command} returned #{output}, return code: #{return_code}"

                case action
                    when :start!, :restart! then
                        case return_code
                            when 0 then
                                return RUNNING
                            else
                                return STOPPED
                        end
                    when :stop! then
                        case return_code
                            when 0 then
                                return STOPPED
                            else
                                return RUNNING
                        end
                    when :status then
                        case return_code
                            when 1 then
                                RUNNING
                            when 0 then
                                STOPPED
                            else
                                UNKNOWN
                        end
                    else
                        return UNKNOWN
                end
            end
        end

        private

        # Returns the path to the launcher script
        # See https://github.com/brianm/galaxy-package-spec for semantics
        def launcher_path(deployment_path)
            xnctl = File.join(deployment_path, "bin", "launcher")
            xnctl = "/bin/sh #{xnctl}" unless FileTest.executable?(xnctl)
            xnctl
        end
    end
end
