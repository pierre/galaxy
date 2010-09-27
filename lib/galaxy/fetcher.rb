require 'galaxy/temp'
require 'galaxy/host'

module Galaxy
    class Fetcher
        def initialize base_url, log
            @base, @log = base_url, log
        end

        # return path on filesystem to the binary
        def fetch type, version, extension="tar.gz"
            core_url = "#{@base}/#{type}-#{version}.#{extension}"
            tmp = Galaxy::Temp.mk_auto_file "galaxy-download"
            @log.info "Fetching #{core_url} into #{tmp}"
            if @base =~ /^http:/
                begin
                    output = Galaxy::HostUtils.system("curl -D - #{core_url} -o #{tmp} -s")
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
