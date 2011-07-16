require 'logger'
require 'net/http'
require 'yaml'

# Create the base module for libraries
module Galaxy
    module Agent
        BASE = File.dirname(__FILE__)
        VERSION = "4.0.0"
    end
end
require File.expand_path(File.join(Galaxy::Agent::BASE, 'drb_server'))
require File.expand_path(File.join(Galaxy::Agent::BASE, 'http_server'))

module Galaxy::Agent
    class Agent
        ANNOUNCEMENT_HEADERS = {'Content-Type' => 'text/plain; charset=utf-8', 'Connection' => 'close'}

        def initialize(options)
            @options = options
            @console_uri = URI.parse(@options[:console_url])

            setup_logging

            @log.info("Agent configuration: #{OpenStruct.new(options)}")
            setup_server

            # Heartbeat to the console
            setup_heartbeat

            # Main server loop
            @server.join
        end

        # Current Agent state
        def status
            {
                "agent_id" => @options[:agent_id],
                "agent_group" => @options[:agent_group],
                "url" => @options[:agent_url],
                "os" => "TODO",
                "machine" => @options[:machine],
                "core_type" => "TODO",
                "config_path" => "TODO",
                "build" => "TODO",
                "status" => "TODO",
                "last_start_time" => "TODO",
                "agent_status" => 'online',
                "galaxy_version" => VERSION,
                "slot_info" => "TODO"
            }
        end

        private

        def setup_logging
            shift_age = 0
            shift_size = 1048576
            case @options[:log]
                when "SYSLOG"
                    # TODO
                    @log = Galaxy::HostUtils.logger "galaxy"
                when "STDOUT"
                    @log = Logger.new(STDOUT, shift_age, shift_size)
                when "STDERR"
                    @log = Logger.new(STDERR, shift_age, shift_size)
                else
                    @log = Logger.new(logdev, shift_age, shift_size)
            end
            @log.level= begin
                case @options[:log_level]
                    when "DEBUG"
                        Logger::DEBUG
                    when "INFO"
                        Logger::INFO
                    when "WARN"
                        Logger::WARN
                    when "ERROR"
                        Logger::ERROR
                end
            end
            @log.info("Initialized Galaxy Agent logging")
        end

        # Up to Galaxy 4.0.0, Console - Agent communication for actions is done over DRb
        # We keep this code for legacy reasons. Moving forward, the protocol will be pure HTTP
        def setup_server
            if @options[:agent_url].match(/^https?:/)
                @server = Galaxy::Agent::HTTPServer.new(@options[:agent_url], self, @log)
            else
                @server = Galaxy::Agent::DRbServer.new(@options[:agent_url], self, @log)
            end
            @log.info("Agent server initialized")
        end

        def setup_heartbeat
            @heartbeat = Thread.start do
                loop do
                    @log.debug("Sleeping #{@options[:announce_interval]} seconds until next heartbeat")
                    sleep(@options[:announce_interval].to_i)
                    begin
                        announce
                    rescue Exception => e
                        @log.warn("Unable to communicate with console, #{e.message}")
                    end
                end
            end
        end

        # Since Galaxy 2.5.x, announcements are handled over HTTP (not DRb)
        # The agent POST its status (YAML format)
        def announce
            Net::HTTP.start(@console_uri.host, @console_uri.port) do |http|
                url, status_data = get_announcement_url_and_payload
                status_data = status_data.to_yaml
                @log.debug("POSTing status to console: #{status_data}")
                response = http.send_request('POST', url, status_data, ANNOUNCEMENT_HEADERS)
                @log.debug("Announcement response from console: #{response.code} #{response.message}: #{response.body}")
            end
        end

        # The new console doesn't care about OpenStruct, send real YAML
        # (we could send json but we don't want to require an extra gem on the box).
        # Also, in the new world, the API is versioned.
        def get_announcement_url_and_payload
            if @options[:legacy]
                return @console_uri.request_uri, OpenStruct.new(status)
            else
                return @console_uri.request_uri + "rest/1.0/deployment", status
            end
        end
    end
end