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
