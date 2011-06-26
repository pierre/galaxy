module Galaxy
    module AgentRemoteApi
        # Command to become a specific core
        def become! requested_config_path, versioning_policy = Galaxy::Versioning::StrictVersioningPolicy # TODO - make this configurable w/ default
            lock

            current_deployment = current_deployment_number

            begin
                requested_config = Galaxy::SoftwareConfiguration.new_from_config_path(requested_config_path)

                unless config.config_path.nil? or config.config_path.empty?
                    current_config = Galaxy::SoftwareConfiguration.new_from_config_path(config.config_path) # TODO - this should already be tracked
                    unless versioning_policy.assignment_allowed?(current_config, requested_config)
                        error_reason = "Versioning policy does not allow this version assignment"
                        raise error_reason
                    end
                end

                build_properties = @prop_builder.build(requested_config.config_path, "build.properties")
                type = build_properties['type']
                build = build_properties['build']
                os = build_properties['os']

                if type.nil?
                    error_reason = "Cannot determine binary type for #{requested_config.config_path}"
                    raise error_reason
                end

                if build.nil?
                    error_reason = "Cannot determine build number for #{requested_config.config_path}"
                    raise error_reason
                end

                if os and os != @os
                    error_reason = "Cannot assign #{requested_config.config_path} to #{@os} host (requires #{os})"
                    raise error_reason
                end

                @logger.info "Becoming #{type}-#{build} with #{requested_config.config_path}"

                stop!

                archive_path = @fetcher.fetch type, build

                new_deployment = current_deployment + 1

                # Update the slot_info to reflect the new deployment state
                slot_info.update requested_config.config_path, deployer.core_base_for(new_deployment)
                core_base = deployer.deploy(new_deployment, archive_path, requested_config.config_path)

                deployer.activate(new_deployment)
                FileUtils.rm(archive_path) if archive_path && File.exists?(archive_path)

                new_deployment_config = OpenStruct.new(:core_type => type,
                                                       :build => build,
                                                       :core_base => core_base,
                                                       :config_path => requested_config.config_path,
                                                       :auto_start => true)
                write_config new_deployment, new_deployment_config
                self.current_deployment_number = new_deployment

                announce
                return status
            rescue Exception => e
                # Roll slot_info back
                slot_info.update config.config_path, deployer.core_base_for(current_deployment)

                error_reason = "Unable to become #{requested_config_path}: #{e}"
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
            end
        end

        # Invoked by 'galaxy update-config <version>'
        def update_config! requested_version, versioning_policy = Galaxy::Versioning::StrictVersioningPolicy # TODO - make this configurable w/ default
            lock

            begin
                @logger.info "Updating configuration to version #{requested_version}"

                if config.config_path.nil? or config.config_path.empty?
                    error_reason = "Cannot update configuration of unassigned host"
                    raise error_reason
                end

                current_config = Galaxy::SoftwareConfiguration.new_from_config_path(config.config_path) # TODO - this should already be tracked
                requested_config = current_config.dup
                requested_config.version = requested_version

                unless versioning_policy.assignment_allowed?(current_config, requested_config)
                    error_reason = "Versioning policy does not allow this version assignment"
                    raise error_reason
                end

                build_properties = @prop_builder.build(requested_config.config_path, "build.properties")
                type = build_properties['type']
                build = build_properties['build']

                if type.nil?
                    error_reason = "Cannot determine binary type for #{requested_config.config_path}"
                    raise error_reason
                end

                if build.nil?
                    error_reason = "Cannot determine build number for #{requested_config.config_path}"
                    raise error_reason
                end

                if config.core_type != type
                    error_reason = "Binary type differs (#{config.core_type} != #{type})"
                    raise error_reason
                end

                if config.build != build
                    error_reason = "Binary build number differs (#{config.build} != #{build})"
                    raise error_reason
                end

                @logger.info "Updating configuration to #{requested_config.config_path}"

                controller = Galaxy::Controller.new slot_info, config.core_base, @logger
                current_deployment = current_deployment_number

                begin
                    slot_info.update requested_config.config_path, deployer.core_base_for(current_deployment)
                    controller.perform! 'update-config', requested_config.config_path
                rescue Exception => e
                    # Roll slot_info back
                    slot_info.update config.config_path, deployer.core_base_for(current_deployment)

                    error_reason = "Failed to update configuration for #{requested_config.config_path}: #{e}"
                    raise error_reason
                end

                @config = OpenStruct.new(:core_type => type,
                                         :build => build,
                                         :core_base => config.core_base,
                                         :config_path => requested_config.config_path)

                write_config(current_deployment, @config)

                announce
                return status
            rescue => e
                error_reason = "Unable to update configuration to version #{requested_version}: #{e}"
                @logger.error error_reason
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

        # Cleanup up to the previous deployment
        def cleanup!
            lock

            begin
                deployer.cleanup_up_to_previous current_deployment_number, @db
                announce
                return status
            rescue Exception => e
                error_reason = "Unable to cleanup: #{e}"
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
            end
        end

        # Stop the current core
        def stop!
            lock

            begin
                if config.core_base
                    @config.state = "stopped"
                    write_config current_deployment_number, @config
                    @logger.debug "Stopping core"
                    @starter.stop! config.core_base
                end

                announce
                return status
            rescue Exception => e
                error_reason = "Unable to stop: #{e}"
                error_reason += "\n#{e.message}" if e.class == Galaxy::HostUtils::CommandFailedError
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
            end
        end

        # Start the currently deployed core
        def start!
            lock

            begin
                if config.core_base
                    @config.state = "started"
                    write_config current_deployment_number, @config
                    @logger.debug "Starting core"
                    @starter.start! config.core_base
                    @config.last_start_time = time
                end

                announce
                return status
            rescue Exception => e
                error_reason = "Unable to start: #{e}"
                error_reason += "\n#{e.message}" if e.class == Galaxy::HostUtils::CommandFailedError
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
            end
        end

        # Restart the currently deployed core
        def restart!
            lock

            begin
                if config.core_base
                    @config.state = "started"
                    write_config current_deployment_number, @config
                    @logger.debug "Restarting core"
                    @starter.restart! config.core_base
                    @config.last_start_time = time
                end

                announce
                return status
            rescue Exception => e
                error_reason = "Unable to restart: #{e}"
                error_reason += "\n#{e.message}" if e.class == Galaxy::HostUtils::CommandFailedError
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
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

        # Invoked by 'galaxy perform <command> [arguments]'
        def perform! command, args = ''
            lock

            begin
                @logger.info "Performing command #{command} with arguments #{args}"
                controller = Galaxy::Controller.new slot_info, config.core_base, @logger
                output = controller.perform! command, args

                announce
                return status, output
            rescue Exception => e
                error_reason = "Unable to perform command #{command}: #{e}"
                @logger.error error_reason
                raise error_reason
            ensure
                unlock
            end
        end

        # Return a nice formatted version of Time.now
        def time
            Time.now.strftime("%m/%d/%Y %H:%M:%S")
        end
    end
end
