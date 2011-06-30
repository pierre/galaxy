require 'galaxy/temp'
require 'galaxy/host'

module Galaxy
    class Fetcher
        def initialize base_url, http_user, http_password, log
            @base, @http_user, @http_password, @log = base_url, http_user, http_password, log
        end

        # return path on filesystem to the binary
        def fetch build, build_uri=nil, extension="tar.gz"

            core_url = build_uri || @base

            if !build.group.nil?
              group_path=build.group.gsub /\./, '/'
              # Maven repo compatible
              core_url = "#{core_url}/#{group_path}/#{build.artifact}/#{build.version}"
            end

            core_url="#{core_url}/#{build.artifact}-#{build.version}.#{extension}"

            tmp = Galaxy::Temp.mk_auto_file "galaxy-download"
            @log.info("Fetching #{core_url} into #{tmp}")
            if core_url =~ /^https?:/
                begin
                    curl_command = "curl -D - #{core_url} -o #{tmp} -s"
                    if !@http_user.nil? && !@http_password.nil?
                      curl_command << " -u #{@http_user}:#{@http_password}"
                    end

                    @log.debug("Running CURL command: #{curl_command}")
                    output = Galaxy::HostUtils.system(curl_command)
                rescue Galaxy::HostUtils::CommandFailedError => e
                    raise "Failed to download archive #{core_url}: #{e.message}"
                end
                status = output.first
                (protocol, response_code, response_message) = status.split
                unless response_code == '200'
                    raise "Failed to download archive #{core_url}: #{status}"
                end
            else
                open(core_url) do |io|
                    File.open(tmp, "w") { |f| f.write(io.read) }
                end
            end
            return tmp
        end
    end
end
