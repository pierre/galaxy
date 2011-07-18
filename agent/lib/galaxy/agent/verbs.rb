module Galaxy::Agent
    module Verbs
        # Command to become a specific core
        # Create a new assignment for this agent
        def become!(requested_config_path)
            lock

            begin
                stop!
                @latest_deployment_id = @deployer.deploy(requested_config_path)
                @log.info("Deployed #{requested_config_path}, deployment_id is #{@latest_deployment_id}")
                announce
                return status
            rescue Exception => e
                # TODO
                # Roll slot_info back
                #slot_info.update config.config_path, deployer.core_base_for(current_deployment), config_uri, binaries_uri

                error_reason = "Unable to become #{requested_config_path}: #{e}"
                @log.error(error_reason)
                raise error_reason
            ensure
                unlock
            end
        end

        # Rollback to the previous deployment
        def rollback!
            lock

            begin
                stop!

                if current_deployment_number > 0
                    write_config current_deployment_number, OpenStruct.new()
                    @core_base = deployer.rollback current_deployment_number
                    self.current_deployment_number = current_deployment_number - 1
                end

                announce
                return status
            rescue => e
                error_reason = "Unable to rollback: #{e}"
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
            end
        end

        # Default arguments in blocks don't work in 1.8.7
        [:start!, :stop!, :restart!].each do |action|
            define_method(action) do
                self.send(action, @latest_deployment_id)
            end
        end

        [:start!, :stop!, :restart!].each do |action|
            define_method(action) do |deployment_id|
                @log.info("Invoking #{action} on deployment_id=#{deployment_id}")
                lock

                begin
                    # TODO
                    #@config.state = "started"
                    #write_config current_deployment_number, @config
                    @starter.send(action, deployment_id)
                    #@config.last_start_time = time

                    announce
                    return status
                rescue Exception => e
                    error_reason = "Unable to #{action}: #{e}"
                    #error_reason += "\n#{e.message}" if e.class == Galaxy::HostUtils::CommandFailedError
                    @log.warn(error_reason)
                ensure
                    unlock
                end
            end
        end

        # Called by the galaxy 'clear' command
        def clear!
            lock

            begin
                stop!

                @logger.debug "Clearing core"
                deployer.deactivate current_deployment_number
                self.current_deployment_number = current_deployment_number + 1

                announce
                return status
            ensure
                unlock
            end
        end

        def lock
            @lock.mutex.synchronize do
                raise "Agent is locked performing another operation" unless @lock.owner.nil? || @lock.owner == Thread.current

                @lock.owner = Thread.current if @lock.owner.nil?

                @log.debug "Locking from #{caller[2]}" if @lock.count == 0
                @lock.count += 1
            end
        end

        def unlock
            @lock.mutex.synchronize do
                raise "Lock not owned by current thread" unless @lock.owner.nil? || @lock.owner == Thread.current
                @lock.count -= 1
                @lock.owner = nil if @lock.count == 0

                @log.debug "Unlocking from #{caller[2]}" if @lock.count == 0
            end
        end
    end
end
