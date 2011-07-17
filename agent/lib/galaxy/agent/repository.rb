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

require 'open-uri'

module Galaxy::Agent
    class Repository
        def initialize(base)
            @binaries_repo = base
        end

        # Recursively concat property files together with the same name, e.g. given
        #   /foo/bar/baz
        #   /foo/baz
        #   /baz
        # the method returns properties from all baz files concated together
        #
        # Returns the raw content of the files
        def walk(hierarchy, file_name)
            result = ""
            hierarchy.split(/\//).inject([]) do |history, part|
                history << part
                begin
                    path = "#{history.join("/")}/#{file_name}"
                    url = "#{@binaries_repo}#{path}"
                    open(url) do |io|
                        data = io.read
                        if block_given?
                            yield path, data
                        end
                        result << data
                    end
                rescue
                end
                history
            end

            result
        end

        # Recursively concat property files together with the same name, e.g. given
        #   /foo/bar/baz
        #   /foo/baz
        #   /baz
        # the method returns properties from all baz files concated together
        #
        # Returns a hash
        def get_props(hierarchy, file_name)
            props = {}
            data = walk(hierarchy, file_name)
            parse_props(data, props)
        end

        # Extract properties (key = value) from a file
        # Returns a hash
        def parse_props(lines, props={})
            lines.split("\n").each do |line|
                if line =~ /^(\s)*#/
                    # comment, ignore
                elsif line =~ /^([^=]+)\s*=(.*)$/
                    props[$1.strip] = $2.strip
                end
            end
            props
        end
    end
end
