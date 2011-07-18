#
# Copyright 2011 Ning, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(Galaxy::Agent::BASE, 'host'))

module Galaxy::Agent
    # Responsible for the lifecycle of the core (start, stop, restart, ...)
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
                # Add slot-info
                command = "#{launcher_path(path)} #{action.to_s.chomp('!')}"

                @log.info "Running #{command}"
                output, return_code = HostUtils.system(command)
                launcher_msg = "`#{command}` exited with status code #{return_code}, returned: #{output}"
                @log.debug(launcher_msg)

                case action
                    when :start!, :restart! then
                        case return_code
                            when 0 then
                                return RUNNING
                            when 1 then
                                return STOPPED
                            else
                                raise RuntimeError.new(launcher_msg)
                        end
                    when :stop! then
                        case return_code
                            when 0 then
                                return STOPPED
                            when 1 then
                                return RUNNING
                            else
                                raise RuntimeError.new(launcher_msg)
                        end
                    when :status then
                        case return_code
                            when 1 then
                                RUNNING
                            when 0 then
                                STOPPED
                            else
                                raise RuntimeError.new(launcher_msg)
                        end
                    else
                        raise RuntimeError.new(launcher_msg)
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
