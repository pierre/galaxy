require 'ostruct'
require 'logger'
require 'galaxy/filter'
require 'galaxy/transport'

module Galaxy
    class ProxyConsole
        attr_reader :db
        @@max_conn_failures = 3

        def initialize drb_url, console_url, log, log_level, ping_interval
            @log =
                case log
                    when "SYSLOG"
                        Galaxy::HostUtils.logger "galaxy-console"
                    when "STDOUT"
                        Logger.new STDOUT
                    when "STDERR"
                        Logger.new STDERR
                    else
                        Logger.new log
                end
            @log.level = log_level
            @drb_url = drb_url
            @ping_interval = ping_interval
            @db = {}
            @mutex = Mutex.new
            @conn_failures = 0

            @console_proxyied_url = console_url
            @console_proxied = Galaxy::Transport.locate(console_url)

            Thread.new do
                loop do
                    begin
                        sleep @ping_interval
                        synchronize
                        if @conn_failures > 0
                            @log.warn "Communication with the master gonsole re-established"
                        end
                        # Reset the number of connection failures
                        @conn_failures = 0
                    rescue DRb::DRbConnError => e
                        @conn_failures += 1
                        @log.warn "Unable to communicate with the master gonsole (#{@conn_failures})"
                        if @conn_failures >= @@max_conn_failures
                            @log.error "Number of connection failures reached"
                            shutdown
                            exit("Connection Error")
                        end
                        retry
                    rescue Exception => e
                        @log.warn "Uncaught exception in agent ping thread: #{e}"
                        @log.warn e.backtrace
                        abort("Unkown Error")
                    end
                end
            end
        end

        def synchronize
            @mutex.synchronize do
                @db = @console_proxied.db
                @log.info "Synchronized with master gonsole at #{@console_proxyied_url}"
                @log.debug "Got new db: #{@db}"
            end
        end

        # Remote API
        def agents filters = {:set => :all}
            filter = Galaxy::Filter.new filters
            @mutex.synchronize do
                @db.values.select(& filter)
            end
        end

        # Remote API
        def log msg
            @log.info msg
        end

        def ProxyConsole.start args
            host = args[:host] || "localhost"
            drb_url = args[:url] || "druby://" + host # DRB transport
            drb_url += ":4440" unless drb_url.match ":[0-9]+$"

            console_proxyied_url = args[:console_proxyied_url] || "druby://localhost"
            console_proxyied_url += ":4440" unless console_proxyied_url.match ":[0-9]+$"

            console = ProxyConsole.new drb_url, console_proxyied_url,
                                       args[:log] || "STDOUT",
                                       args[:log_level] || Logger::INFO,
                                       args[:ping_interval] || 5

            Galaxy::Transport.publish drb_url, console # DRB transport
            console
        end

        def shutdown
            Galaxy::Transport.unpublish @drb_url
        end

        def join
            Galaxy::Transport.join @drb_url
        end
    end
end
