module Galaxy
    class Transport
        @@transports = []

        def self.register transport
            @@transports << transport
        end

        def self.locate url, log=nil
            handler_for(url).locate url, log
        end

        def self.publish url, object, log=nil
            handler_for(url).publish url, object, log
        end

        def self.unpublish url
            handler_for(url).unpublish url
        end

        def self.handler_for url
            @@transports.select { |t| t.can_handle? url }.first or raise "No handler found for #{url}"
        end

        def initialize pattern
            @pattern = pattern
        end

        def can_handle? url
            @pattern =~ url
        end

        def self.join url
            handler_for(url).join url
        end
    end

    class DRbTransport < Transport
        require 'drb'

        def initialize
            super(/^druby:.*/)
            @servers = {}
        end

        def locate url, log=nil
            DRbObject.new_with_uri url
        end

        def publish url, object, log=nil
            log.debug("Starting DRB for #{url}") unless log.nil?
            @servers[url] = DRb.start_service url, object
        end

        def unpublish url
            @servers[url].stop_service
            @servers[url] = nil
        end

        def join url
            @servers[url].thread.join
        end
    end

    class LocalTransport < Transport
        def initialize
            super(/^local:/)
            @servers = {}
        end

        def locate url, log=nil
            @servers[url]
        end

        def publish url, object, log=nil
            @servers[url] = object
        end

        def unpublish url
            @servers[url] = nil
        end

        def join url
            raise "Not yet implemented"
        end
    end

    # This http transport isn't used in Galaxy 2.4, which uses http only for anonucements. However, this code shows
    # how announcements could be merged via transport. The unit test for this class shows one-direction communication
    # (eg, for announcements). To do two way, servers (eg, locate()) would be needed on both sides.
    # Note that the console code assumes that the transport initialize blocks, so the calling code (eg console) waits
    # for an explicit 'join'. But the Announcer class used here starts a server without blocking and returns immediately.
    # Therefore, explicit join is not necessary. So to use, make the console work like the agent: track the main polling
    # thread started in initialize() and kill/join when done.
    #
    class HttpTransport < Transport
        require 'galaxy/announcements'

        def initialize
            super(/^http:.*/)
            @servers = {}
            @log = nil
        end

        # get object (ie announce fn)
        # - install announce() callback
        def locate url, log=nil
            #DRbObject.new_with_uri url
            HTTPAnnouncementSender.new url, log
        end

        # make object available (ie console)
        def publish url, obj, log=nil
            if !obj.respond_to?('process_get') || !obj.respond_to?('process_post')
                raise TypeError.new("#{obj.class.name} doesn't contain 'process_post' and 'process_get' methods")
            end
            return @servers[url] if @servers[url]
            begin
                 @servers[url] = Galaxy::HTTPServer.new(url, obj)
            rescue NameError
                 raise NameError.new("Unable to create the http server. Is mongrel installed?")
            end
            return @servers[url]
        end

        def unpublish url
            @servers[url].shutdown
            @servers[url] = nil
        end

        def join url
            #nop
        end
    end
end

Galaxy::Transport.register Galaxy::DRbTransport.new
Galaxy::Transport.register Galaxy::LocalTransport.new
Galaxy::Transport.register Galaxy::HttpTransport.new

# Disable DRb persistent connections (monkey patch)
module DRb
    class DRbConn
        remove_const :POOL_SIZE
        POOL_SIZE = 0
    end
end
