require 'fileutils'
require 'tempfile'
require 'logger'
require 'galaxy/host'

module Galaxy
    class Deployer
        attr_reader :log

        def initialize deploy_dir, log, machine, identifier, group
            @base, @log, @machine, @identifier, @group = deploy_dir, log, machine, identifier, group
        end

        # number is the deployment number for this agent
        # archive is the path to the binary archive to deploy
        # props are the properties (configuration) for the core
        def deploy number, archive, config_path, repository_base, binaries_base
            core_base = File.join(@base, number.to_s);
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

            command = "#{xndeploy} --base #{core_base} --binaries #{binaries_base} --config-path #{config_path} --repository #{repository_base} --machine #{@machine} --id #{@identifier} --group #{@group}"
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
