require 'uri'
require 'webrick'

include WEBrick

module Galaxy::Agent
    class DeploymentServlet < HTTPServlet::AbstractServlet
        def initialize(server, agent, log)
            super(server)
            @agent = agent
            @log = log
        end

        # Status of the deployment (galaxy show)
        def do_GET(req, resp)
            resp.status = 200
            resp['Content-Type'] = "application/json"

            body = @agent.status.marshal_dump.to_s
            @log.debug("GET response: #{body}")
            resp.body = body
        end

        # Create a new deployment (galaxy assign, galaxy update)
        def do_POST(req, resp)
            raise HTTPStatus::OK
        end

        # Update a deployment (galaxy update-config)
        def do_PUT(req, resp)
            raise HTTPStatus::OK
        end

        # Clear deployment (galaxy clear)
        def do_DELETE(req, resp)
            raise HTTPStatus::OK
        end
    end

    class HTTPServer
        def initialize(uri, agent, log=Logger.new)
            @agent = agent
            @log = log
            uri = URI.parse(uri)

            config = {}
            config.update(:BindAddress => uri.host,
                          :Port => uri.port,
                          :Logger => log,
                          :AccessLog => [nil, nil])

            @server = HTTPServer.new(config)
            @server.mount("/rest/1.0/deployment", DeploymentServlet, @agent, @log)

            @log.info("Starting Galaxy Agent")

            Thread.start { @server.start }
        end

        def shutdown
            @log.info("Shutting down Galaxy Agent")
            @server.shutdown
        end
    end
end