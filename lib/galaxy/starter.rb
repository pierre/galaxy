require 'fileutils'
require 'galaxy/host'
require 'logger'

module Galaxy
    class Starter
        def initialize log
            @log = log
        end

        [:start!, :restart!, :stop!, :status].each do |action|
            define_method action.to_s do |path|
                return "unknown" if path.nil?
                launcher_path = xnctl_path(path)

                command = "#{launcher_path} #{action.to_s.chomp('!')}"
                @log.debug "Running #{command}"
                begin
                    output = Galaxy::HostUtils.system command
                    @log.debug "#{command} returned: #{output}"
                    # Command returned 0, return status of the app
                    case action
                        when :start!
                        when :restart!
                            return "running"
                        when :stop!
                        when :status
                            return "stopped"
                        else
                            return "unknown"
                    end
                rescue Galaxy::HostUtils::CommandFailedError => e
                    # status is special
                    if action == :status
                        if e.exitstatus == 1
                            return "running"
                        else
                            return "unknown"
                        end
                    end

                    @log.warn "Unable to #{action}: #{e.message}"
                    raise e
                end
            end
        end

        private

        def xnctl_path path
            xnctl = File.join(path, "bin", "launcher")
            xnctl = "/bin/sh #{xnctl}" unless FileTest.executable? xnctl
            xnctl
        end
    end
end
