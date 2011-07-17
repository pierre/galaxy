require 'open-uri'

module Galaxy::Agent
    class Fetcher
        def initialize(base_url, http_user, http_password, log)
            @base, @http_user, @http_password, @log = base_url, http_user, http_password, log
        end

        # return path on filesystem to the binary
        def fetch(build, extension="tar.gz")
            core_url = @base

            if !build.group.nil?
                group_path=build.group.gsub /\./, '/'
                # Maven repo compatible
                core_url = "#{core_url}/#{group_path}/#{build.artifact}/#{build.version}"
            end
            core_url="#{core_url}/#{build.artifact}-#{build.version}.#{extension}"

            config = {}
            unless (@http_user.nil? || @http_password.nil?)
                config[:http_basic_authentication] = [@http_user, @http_password]
            end
            tmp = Tempfile.open("galaxy-download")
            @log.info("Fetching #{core_url} into #{tmp.path}")
            open(core_url, config) do |io|
                File.open(tmp, "w") { |f| f.write(io.read) }
            end
            tmp
        end
    end
end
