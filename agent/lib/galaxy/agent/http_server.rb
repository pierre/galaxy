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

        # Status of the deployment
        #
        # /rest/1.0/deployment/<id>
        #
        def do_GET(req, resp)
            ok_response(resp)
        end

        # galaxy assign - create a new deployment
        # Note: galaxy update and rollback are wrappers around assign.
        #
        # /rest/1.0/deployment
        #
        # The request body contains the configuration (YAML), e.g.
        #  "--- \nconfig_path: /qa/15.0/coll\n"
        # Response contains the id of the deployment
        #
        #
        # galaxy start/stop/restart
        #
        # /rest/1.0/deployment/<id>
        #
        # The request body contains the action (YAML), e.g.
        #  "--- \naction: start\n"
        def do_POST(req, resp)
            assignment = OpenStruct.new(YAML.load(req.body))
            @log.info("Becoming: build=#{assignment.build}, config=#{assignment.config}, config_uri=#{assignment.config_uri}, binaries_uri=#{assignment.binaries_uri}")
            agent.become(assignment.build, assignment.config, assignment.config_uri, assignment.binaries_uri)
            ok_response(resp)
        end

        # galaxy update-config: update an existing deployment's configuration
        #
        # /rest/1.0/deployment/<id>
        #
        def do_PUT(req, resp)
            assignment = OpenStruct.new(YAML.load(req.body))
            @log.info("Updating: version=#{assignment.version}, config_uri=#{assignment.config_uri}, binaries_uri=#{assignment.binaries_uri}")
            agent.update_config(assignment.version, assignment.config_uri, assignment.binaries_uri)
            ok_response(resp)
        end

        # galaxy clear: clear deployment
        #
        # /rest/1.0/deployment/<id>
        #
        def do_DELETE(req, resp)
            ok_response(resp)
        end

        private

        def ok_response(resp)
            resp.status = 200
            resp['Content-Type'] = "application/yaml"
            resp.body = YAML.dump(@agent.status)
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