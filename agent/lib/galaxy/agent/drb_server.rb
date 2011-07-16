require 'drb'

# DRb version
module Galaxy::Agent
    class DeploymentService
        def initialize(agent, log)
            @agent = agent
            @log = log
        end

        def status
            @agent.status
        end

        def become!(build, config, config_uri=nil, binaries_uri=nil)
            @log.info("Becoming: build=#{build}, config=#{config}, config_uri=#{config_uri}, binaries_uri=#{binaries_uri}")
            status
        end

        def update_config!(version, config_uri=nil, binaries_uri=nil)
            @log.info("Updating: version=#{version}, config_uri=#{config_uri}, binaries_uri=#{binaries_uri}")
            status
        end

        def rollback!
            @log.info("Rolling back")
            status
        end

        def cleanup!
            @log.info("Cleanup")
            status
        end

        def stop!
            @log.info("Stopping")
            status
        end

        def start!
            @log.info("Starting")
            status
        end

        def restart!
            @log.info("Restarting")
            status
        end

        def clear!
            @log.info("clearing")
            status
        end

        def perform!(command, args = '')
            @log.warn("Unsupported")
        end

        def time
            @log.warn("Unsupported")
        end
    end

    class DRbServer
        def initialize(uri, agent, log=Logger.new)
            @agent = agent
            @log = log
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