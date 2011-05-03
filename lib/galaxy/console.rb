require 'ostruct'
require 'logger'
require 'rubygems'
begin
    # We don't install the json gem by default on our machines.
    # Not critical, since it is for the HTTP API that will be rolled in the future
    require 'json'
    $JSON_LOADED = true
rescue LoadError
    $JSON_LOADED = false
end
require 'resolv'

require 'galaxy/filter'
require 'galaxy/log'
require 'galaxy/transport'
require 'galaxy/announcements'

module Galaxy
    class Console
        attr_reader :db, :drb_url, :http_url, :ping_interval, :host, :env, :logger

        def self.locate url
            Galaxy::Transport.locate url
        end

        def initialize drb_url, http_url, log, log_level, ping_interval, host, env
            @host = host
            @env = env

            @drb_url = drb_url
            @http_url = http_url

            @logger = Galaxy::Log::Glogger.new(log)
            @logger.log.level = log_level

            @ping_interval = ping_interval
            @db = {}
            @mutex = Mutex.new

            Thread.new do
                loop do
                    begin
                        cutoff = Time.new
                        sleep @ping_interval
                        ping cutoff
                    rescue Exception => e
                        @logger.warn "Uncaught exception in agent ping thread: #{e}"
                        @logger.warn e.backtrace
                    end
                end
            end
        end

        # Remote API
        def reap agent_id, agent_group
            key = "#{agent_id}/#{agent_group}"
            @mutex.synchronize do
                @db.delete key
            end
        end

        # Return agents matching a filter query
        # Used by both HTTP and DRb API.
        def agents filters = {}
            # Log command run by the client
            if filters[:command]
                @logger.info filters[:command]
                filters.delete :command
            end

            filters = {:set => :all} if (filters.empty? or filters.nil?)

            filter = Galaxy::Filter.new filters
            @logger.debug "Filtering agents by #{filter}"

            @mutex.synchronize do
                @db.values.select(& filter)
            end
        end

        # Process announcement (ping) from agent (HTTP API)
        #
        # this function is called as a callback from http post server. We could just use the announce function as the
        # callback, but using this function allows us to add in different stats for post announcements.
        def process_post announcement
            announce announcement
        end

        include Galaxy::HTTPUtils

        # Return agents matching a filter query (HTTP API).
        #
        # Note that & in the query means actually OR.
        def process_get query_string
            # Convert env=prod&host=prod-1.company.com to {:env => "prod", :host =>
            # "prod-1.company.com"}
            filters = {}
            CGI::parse(query_string).each { |k, v| filters[k.to_sym] = v.first }
            if $JSON_LOADED
                return agents(filters).to_json
            else
                return agents(filters).inspect
            end
        end

        def Console.start args
            drb_url = args[:url] || "druby://" + args[:host] # DRB transport
            drb_url += ":4440" unless drb_url.match ":[0-9]+$"

            http_url = args[:announcement_url] || "http://localhost" # http announcements
            http_url = "#{http_url}:4442" unless http_url.match ":[0-9]+$"

            log = args[:log] || "STDOUT"
            log_level = args[:log_level] || Logger::INFO
            ping_interval = args[:ping_interval] || 5
            host = args[:host] || "localhost"

            console = Console.new drb_url, 
                                  http_url,
                                  log,
                                  log_level,
                                  ping_interval,
                                  host, 
                                  args[:environment]

            # DRb transport (galaxy command line client)
            Galaxy::Transport.publish drb_url, console, console.logger

            # HTTP API (announcements, status, ...)
            Galaxy::Transport.publish http_url, console, console.logger

            console
        end

        def shutdown
            Galaxy::Transport.unpublish @http_url
            Galaxy::Transport.unpublish @drb_url
        end

        def join
            Galaxy::Transport.join @http_url
            Galaxy::Transport.join @drb_url
        end

        private

        # Update the agents database
        def announce announcement
            begin
                agent_id = announcement.agent_id
                agent_group = announcement.agent_group
                key = "#{agent_id}/#{agent_group}"
                @logger.debug "Received announcement from #{agent_id}/#{agent_group}."
                @mutex.synchronize do
                    if @db.has_key?(key)
                        unless @db[key].agent_status != "offline"
                            announce_message = "#{key} is now online again"
                            @logger.info announce_message
                        end
                        if @db[key].status != announcement.status
                            announce_message = "#{key} core state changed: #{@db[key].status} --> #{announcement.status}"
                            @logger.info announce_message
                        end
                    else
                        announce_message = "Discovered new agent: #{key} [#{announcement.inspect}]"
                        @logger.info "Discovered new agent: #{key} [#{announcement.inspect}]"
                    end

                    @db[key] = announcement
                    @db[key].timestamp = Time.now
                    @db[key].agent_status = 'online'
                end
            rescue RuntimeError => e
                error_message = "Error receiving announcement: #{e}"
                @logger.warn error_message
            end
        end

        # Iterate through the database to find agents that haven't pinged home
        def ping cutoff
            @mutex.synchronize do
                @db.each_pair do |key, entry|
                    if entry.agent_status != "offline" and entry.timestamp < cutoff
                        error_message = "#{key} failed to announce; marking as offline"
                        @logger.warn error_message

                        entry.agent_status = "offline"
                        entry.status = "unknown"
                    end
                end
            end
        end
    end
end
