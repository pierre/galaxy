require 'fileutils'
require 'tempfile'
require 'logger'
require 'yaml'
require 'galaxy/host'
require 'galaxy/slotinfo'

module Galaxy
    class Deployer
        attr_reader :log

        def initialize repository_base, binaries_base, deploy_dir, log, slot_info
            @repository_base = repository_base
            @binaries_base = binaries_base
            @base = deploy_dir
            @log = log
            @slot_info = slot_info
        end

        def core_base_for number
            core_base = File.join(@base, number.to_s);
        end

        # number is the deployment number for this agent
        # archive is the path to the binary archive to deploy
        # props are the properties (configuration) for the core
        def deploy number, archive, config_path
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

            command = "#{xndeploy} --slot-info #{@slot_info.get_file_name} --base #{core_base} --binaries #{@binaries_base} --config-path #{config_path} --repository #{repository_base}"

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
