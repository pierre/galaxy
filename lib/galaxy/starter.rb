require 'fileutils'
require 'galaxy/host'
require 'logger'

module Galaxy
    class Starter
        def initialize log, db
            @log = log
            @db = db
        end

        [:start!, :restart!, :stop!, :status].each do |action|
            define_method action.to_s do |path|
                return "unknown" if path.nil?
                launcher_path = xnctl_path(path)

                command = "#{launcher_path} --slot-info #{@db.file_for('slot_info')} #{action.to_s.chomp('!')}"
                @log.debug "Running #{command}"
                exitstatus = 0
                begin
                    output = Galaxy::HostUtils.system command
                    @log.debug "#{command} returned: #{output}"
                    # Command returned 0, return status of the app
                    case action
                        when :start!
                        when :restart!
                        when :status
                            return "running"
                        when :stop!
                            return "stopped"
                        else
                            return "unknown"
                    end
                rescue Galaxy::HostUtils::CommandFailedError => e
                    # status is special
                    if action == :status
                        # 1 program is dead and /var/run pid file exists
                        # 2 program is dead and /var/lock lock file exists
                        # 3 program is not running
                        if e.exitstatus >= 1 && e.exitstatus <= 3
                            return "stopped"
                        else
                            return "unknown"
                        end
                    end

                    # non-zero from all other commands is an error
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
