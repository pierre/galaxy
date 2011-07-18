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
    # Responsible for downloading binaries
    class Fetcher

        DEFAULT_BINARY_EXTENSION = "tar.gz"

        def initialize(log, binaries_repo, http_user=nil, http_password=nil)
            @binaries_repo = binaries_repo
            @log = log

            # HTTP config
            @config = {}
            unless (http_user.nil? || http_password.nil?)
                @config[:http_basic_authentication] = [http_user, http_password]
            end
        end

        # Returns the file on filesystem to the downloaded binary
        # The caller is expected to call .close! on it to delete it
        def fetch(build)
            binary_path = construct_binary_path(build)
            tmp = Tempfile.open("galaxy-download")

            @log.info("Fetching #{binary_path} into #{tmp.path}")
            open(binary_path, @config) do |io|
                File.open(tmp, "w") { |f| f.write(io.read) }
            end
            tmp
        end

        # Given the build metadata, construct the path (local filesystem, remote server, ...)
        # to the actual artifact
        # The method is public for unit testing only
        def construct_binary_path(build)
            # If a group is specified, switch to Maven repo layout
            # Otherwise, we default to the old Gepo behavior
            binary_path = @binaries_repo
            unless build.group.nil?
                group_path = build.group.gsub /\./, '/'
                binary_path = "#{@binaries_repo}/#{group_path}/#{build.artifact}/#{build.version}"
            end
            "#{binary_path}/#{build.artifact}-#{build.version}.#{DEFAULT_BINARY_EXTENSION}"
        end
    end
end
