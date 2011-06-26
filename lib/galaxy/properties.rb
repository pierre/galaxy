#!/usr/bin/env ruby
require 'open-uri'
require 'logger'

module Galaxy
    module Properties

        def Properties.parse_props io, props={}
            io.each_line do |line|
                if line =~ /^(\s)*#/
                    # comment, ignore
                elsif line =~ /^([^=]+)\s*=(.*)$/
                    props[$1.strip] = $2.strip
                end

            end
            props
        end

        class Builder
            def initialize(base, http_user, http_password, log=Logger.new(STDOUT))
              @base = base
                @log = log
                if !http_user.nil? && !http_password.nil?
                  @http_auth = {:http_basic_authentication =>[http_user, http_password]}
                end
            end

            def build hierarchy, file_name
                props = {}

                hierarchy.split(/\//).inject([]) do |history, part|
                    history << part
                    begin

                      url = "#{@base}#{history.join("/")}/#{file_name}"
                      @log.debug "Fetching #{url}"

                      auth = url =~ /^https?:\/\// ? {} : nil
                      begin
                        fetch_done = true
                        open(url, auth) do |io|
                          Properties.parse_props io, props
                        end
                      rescue OpenURI::HTTPError => http_err
                        if http_err.io.status[0] == "401" && auth.empty? && !@http_auth.nil?
                          # retry with the auth information
                          auth = @http_auth
                          fetch_done = false
                        else
                          raise http_err
                        end
                      end while !fetch_done
                    rescue => e
                      @log.debug e.message
                    end
                    history
                end
                @log.debug props.inspect
                props
            end

            def replace_tokens properties, tokens
                # replace special tokens
                # syntax is #{TOKEN}
                # (old syntax of $TOKEN is deprecated)
                properties.inject({}) do |hash, pair|
                    key, value = pair
                    hash[key] = value
                    tokens.each { |find, replace| hash[key] = hash[key].gsub("$#{find}", replace).gsub("\#{#{find}}", replace) }
                    hash
                end
            end
        end
    end
end
