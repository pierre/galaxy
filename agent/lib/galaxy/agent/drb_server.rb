require 'drb'

# DRb version
module Galaxy::Agent
    # Service exposed via DRb to the console
    class DeploymentService
        def initialize(agent, log)
            @agent = agent
            @log = log
        end

        def become!(config, versioning_policy)
            @log.info("Becoming config=#{config}, versioning_policy=#{versioning_policy}")
            @agent.become!(config)
            status
        end

        def update_config!(version, config_uri=nil, binaries_uri=nil)
            @log.info("Updating: version=#{version}, config_uri=#{config_uri}, binaries_uri=#{binaries_uri}")
            @agent.update_config!(version, config_uri, binaries_uri)
            status
        end

        def status
            @agent.status
        end

        [:start!, :restart!, :stop!, :rollback!, :clear!].each do |action|
            # Pre 4.x.x, one agent was managing one deployment. This is not the case anymore
            define_method(action) do
                @log.info("Agent asked to #{action}")
                @agent.send(action)
                status
            end
        end

        # We don't support perform beginning 4.x.x
        def perform!(command, args = '')
            @log.warn("Unsupported")
            status
        end
    end

    class DRbServer
        def initialize(uri, agent, log=Logger.new)
            @agent = agent
            @log = log
            # In contrary to previous versions, we limit in 4.x.x the scope
            # of methods exposed over DRb (we don't expose the full agent anymore)
            @service = DRb.start_service(uri, DeploymentService.new(agent, log))
            @log.info("Started Galaxy Agent (DRb) on #{DRb.uri}")
        end

        def join
            DRb.thread.join
        end

        def shutdown
            @log.info("Shutting down Galaxy Agent")
            @service.stop_service
        end
    end
end