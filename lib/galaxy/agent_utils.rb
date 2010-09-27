require 'timeout'

module Galaxy
    module AgentUtils
        def ping_agent agent
            Timeout::timeout(5) do
                agent.proxy.status
            end
        end

        module_function :ping_agent
    end
end
