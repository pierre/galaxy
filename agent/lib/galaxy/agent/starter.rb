require 'fileutils'
require 'galaxy/agent/host'
require 'logger'

module Galaxy::Agent
    class Starter
        def initialize(log, db)
            @log = log
            @db = db
        end

        # Given a deployment_id, perform the action on the specified core
        # If deployment_id is nil, perform the action on all cores
        [:start!, :restart!, :stop!, :status].each do |action|
            define_method action.to_s do |deployment_id|
                #TODO agent internal db path=...
                return "unknown" if path.nil?
                launcher_path = launcher_path(path)

                command = "#{launcher_path} --slot-info #{@db.file_for('slot_info')} #{action.to_s.chomp('!')}"
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

        # Return a nice formatted version of Time.now
        def time
            Time.now.strftime("%m/%d/%Y %H:%M:%S")
        end

        def launcher_path(path)
            xnctl = File.join(path, "bin", "launcher")
            xnctl = "/bin/sh #{xnctl}" unless FileTest.executable?(xnctl)
            xnctl
        end
    end
end
