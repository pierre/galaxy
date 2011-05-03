require 'fileutils'
require 'tempfile'
require 'logger'
require 'yaml'
require 'galaxy/host'

module Galaxy
    class Deployer
        attr_reader :log

        def initialize deploy_dir, log, db, machine, agent_id, agent_group, slot_environment = nil
            @base, @log, @db, @machine, @agent_id, @agent_group, @slot_environment = deploy_dir, log, db, machine, agent_id, agent_group, slot_environment
        end

        def core_base_for number
            core_base = File.join(@base, number.to_s);
        end

        # number is the deployment number for this agent
        # archive is the path to the binary archive to deploy
        # props are the properties (configuration) for the core
        def deploy number, archive, config_path, repository_base, binaries_base
            core_base = core_base_for(number)
            FileUtils.mkdir_p core_base

            log.info "deploying #{archive} to #{core_base} with config path #{config_path}"

            command = "#{Galaxy::HostUtils.tar} -C #{core_base} -zxf #{archive}"
            begin
                Galaxy::HostUtils.system command
            rescue Galaxy::HostUtils::CommandFailedError => e
                raise "Unable to extract archive: #{e.message}"
            end

            xndeploy = "#{core_base}/bin/xndeploy"
            unless FileTest.executable? xndeploy
                xndeploy = "/bin/sh #{xndeploy}"
            end

            slot_info = OpenStruct.new(:base => core_base,
                                        :binaries => binaries_base,
                                        :config_path => config_path,
                                        :repository => repository_base,
                                        :machine => @machine,
                                        :agent_id => @agent_id,
                                        :agent_group => @agent_group,
                                        :env => @slot_environment)

            @db['slot_info'] = YAML.dump slot_info

            command = "#{xndeploy} --slot-info #{@db.file_for('slot_info')}"
            begin
                Galaxy::HostUtils.system command
            rescue Galaxy::HostUtils::CommandFailedError => e
                raise "Deploy script failed: #{e.message}"
            end
            return core_base
        end

        def activate number
            core_base = File.join(@base, number.to_s);
            current = File.join(@base, "current")
            if File.exists? current
                File.unlink(current)
            end
            FileUtils.ln_sf core_base, current
            return core_base
        end

        def deactivate number
            current = File.join(@base, "current")
            if File.exists? current
                File.unlink(current)
            end
        end

        def rollback number
            current = File.join(@base, "current")

            if File.exists? current
                File.unlink(current)
            end

            FileUtils.rm_rf File.join(@base, number.to_s)

            core_base = File.join(@base, (number - 1).to_s)
            FileUtils.ln_sf core_base, current

            return core_base
        end

        def cleanup_up_to_previous current, db
            # Keep the current and last one (for rollback)
            (1..(current - 2)).each do |number|
                key = number.to_s

                # Remove deployed bits
                FileUtils.rm_rf File.join(@base, key)

                # Cleanup the database
                db.delete_at key
            end
        end
    end
end
