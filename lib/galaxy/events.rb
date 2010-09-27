require 'rubygems'
require 'galaxy/announcements'

module Galaxy
    # Generic Event sender class
    class EventSender
        COLLECTOR_API_VERSION = 1

        GALAXY_SCHEMA = 'Galaxy'
        GALAXY_LOG_SCHEMA = 'GalaxyLog'
        DUMMY_TYPE = 'dummy'

        attr_reader :type, :log

        def initialize(listener_url, gonsole_url = nil, ip_addr=nil, log=Logger.new(STDOUT))
            @log = log
            @gonsole_url = gonsole_url
            @ip_addr = ip_addr
            @log.debug "Registered Event listener type #{self.class} at #{listener_url}, sender url #{ip_addr}"
            listener_url.nil? ? @uri = nil : @uri = URI.parse(listener_url)
        end

        # To override in the child class. event is an OpenStruct
        def send_event(event)
            # no-op
        end

        private

        def escape str
            # default is URI::REGEXP::UNSAFE is /[^-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]/n
            # and is not enough! (& and , not escaped)
            return URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end

        # Sanitize strings
        def add_field(type, value)
            return "#{type}#{escape(value.to_s)},"
        end

        def do_send_event(formatted_query)
            return if @uri.nil?
            http_query = @uri.merge(formatted_query).to_s
            @log.debug http_query
            begin
                # GET
                res = Net::HTTP.start(@uri.host, @uri.port) do |http|
                    headers = {'Content-Type' => 'text/plain; charset=utf-8'}
                    response = http.send_request('GET', http_query, nil, headers)
                    @log.debug "Event sent to Collector #{@uri.host} = #{http_query}" if @log
                    response # Return the response form the block
                end
                case res
                    when Net::HTTPAccepted
                        return true
                    else
                        res.error!
                end
            rescue Exception => e
                if @log
                    @log.warn "Unable to contact EventListener on #{@uri}"
                    @log.warn "Request: #{http_query}"
                    @log.warn "Client side error: #{e}"
                    @log.warn "Body reponse: #{res.body}" if res
                end
                return false
            end
        end
    end

    # Send logs to HDFS
    class GalaxyLogEventSender < EventSender
        EVENTS_SUPPORTED = [:debug, :error, :fatal, :info, :warn]

        EVENTS_SUPPORTED.each do |loglevel|
            define_method "dispatch_#{loglevel.to_s}_log" do |* args|
                message, progname, * ignored = args
                send_event(generate_event(loglevel.to_s, message, progname))
            end
        end

        private

        # Pre-process logs and generate OpenStruct mapping the GalaxyLog Thrift Schema
        #
        # struct GalaxyLog {
        #    1:i64 date,
        #    2:i32 ip_addr,
        #    3:i16 pid,
        #    4:string severity,
        #    5:string progname,
        #    6:string message
        #}
        def generate_event(severity, message, progname)
            event = OpenStruct.new

            event.date = Time.now.to_i * 1000
            event.gonsole_url = @gonsole_url
            event.ip_addr = @ip_addr
            event.pid = $$
            event.severity = severity.downcase
            event.progname = progname
            event.message = message

            return event
        end

        def send_event(event)
            do_send_event format_url(event)
        end

        private

        def format_url(event)
            url = "/#{COLLECTOR_API_VERSION}?"
            url += "v=#{EventSender::GALAXY_LOG_SCHEMA},"
            url += escape(add_field("8", event.date))
            # Make sure to add a valid number (int) or the collector will choke on it (400 bad request)
            url += escape(add_field("4", (format_ip(event.ip_addr))))
            url += escape(add_field("2", (event.pid || 0)))
            url += escape(add_field("s", event.severity))
            url += escape(add_field("s", event.progname))
            url += escape(add_field("s", event.message))
            url += escape(add_field("s", event.gonsole_url))
            url += "&rt=b"
            return url
        end

        def format_ip(ip_addr)
            if ip_addr.nil? or ip_addr.empty?
                return 0
            end
            addr = 0
            ip_addr.split(".").each do |x|
                addr = addr * 256 + x.to_i
            end
            return addr
        end
    end

    # Send actions related events to HDFS
    class GalaxyEventSender < EventSender
        EVENTS_SUPPORTED = [:announce, :cleanup, :command, :update_config, :become, :rollback, :start, :stop, :clear, :perform, :restart]
        EVENTS_RESULT_SUPPORTED = [:success, :error]

        EVENTS_SUPPORTED.each do |event|
            EVENTS_RESULT_SUPPORTED.each do |result|
                define_method "dispatch_#{event}_#{result}_event" do |status|
                    if status.is_a? String
                        status = OpenStruct.new(:message => status)
                    elsif status.is_a? Hash
                        status = OpenStruct.new(status)
                    end
                    # e.g. perform, announce
                    status.event_type = event
                    # e.g. error, success
                    status.galaxy_event_type = result
                    status.gonsole_url = @gonsole_url
                    send_event(status)
                end
            end
        end

        def send_event(event)
            do_send_event format_url(event)
        end

        private

        def format_url(event)
            url = "/#{COLLECTOR_API_VERSION}?"
            url += "v=#{EventSender::GALAXY_SCHEMA},"
            #url += add_field "8", event.timestamp
            url += escape(add_field("x", "date"))
            url += escape(add_field("s", event.event_type))
            url += escape(add_field("s", event.message))
            url += escape(add_field("s", event.agent_status))
            url += escape(add_field("s", event.os))
            url += escape(add_field("s", event.host))
            url += escape(add_field("s", event.galaxy_version))
            url += escape(add_field("s", event.core_type))
            url += escape(add_field("s", event.machine))
            url += escape(add_field("s", event.status))
            url += escape(add_field("s", event.galaxy_event_type))
            url += escape(add_field("s", event.url))
            url += escape(add_field("s", event.config_path))
            url += escape(add_field("s", event.build))
            url += escape(add_field("s", event.ip))
            url += escape(add_field("s", event.user))
            url += escape(add_field("s", event.gonsole_url))
            url += "&rt=b"
            return url
        end
    end

    # When the user doesn't specify a collector URL
    class DummyEventSender < EventSender
        def initialize()
        end

        def method_missing(m, * args, & block)
        end
    end
end
