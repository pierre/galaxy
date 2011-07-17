require 'yaml'

require File.expand_path(File.join(Galaxy::Agent::BASE, 'fetcher'))
require File.expand_path(File.join(Galaxy::Agent::BASE, 'host'))
require File.expand_path(File.join(Galaxy::Agent::BASE, 'repository'))

module Galaxy::Agent
    # @Singleton
    class Deployer
        def initialize(config_repo, binaries_repo, deploy_dir, data_dir, http_user, http_password, log)
            @deploy_dir = deploy_dir
            @data_dir = data_dir
            @log = log

            # Downloader for configs
            @repository = Repository.new(config_repo)

            # Downloader for binaries
            @fetcher = Fetcher.new(binaries_repo, http_user, http_password, @log)

            # Internal state of deployments - dumped to disk
            @deployments = {}
        end

        def deploy(config_path)
            # Validate the config path (of the form /env/version/build)
            # Using ! as regex delimiter since the config path contains / characters
            unless %r!^/([^/]+)/([^/]+)/(.*)$!.match(config_path)
                raise "Illegal config path '#{config_path}'"
            end

            binary = get_binary_info(config_path)

            # TODO - validate os

            # Create a UUID - we should probably switch to the built-in UUID generator in ruby 1.9
            deployment_id = Time.now.to_i.to_s
            core_base = File.join(@deploy_dir, deployment_id)

            # TODO - do the real deployment

            # Fetch binary
            binary_file = @fetcher.fetch(binary)

            # TODO Deploy and active
            @log.info("Deploying #{binary} with config #{config_path} to #{core_base}")
            FileUtils.mkdir_p core_base
            command = "#{HostUtils.tar} -C #{core_base} -zxf #{binary_file.path}"
            begin
                HostUtils.system command
                # Get rid of the payload
                binary_file.close!
            rescue HostUtils::CommandFailedError => e
                raise "Unable to extract archive: #{e.message}"
            end

            # Invoke post-deployment script
#            xndeploy = "#{core_base}/bin/xndeploy"
#            unless FileTest.executable? xndeploy
#                xndeploy = "/bin/sh #{xndeploy}"
#            end
#            command = "#{xndeploy} --slot-info #{@slot_info.get_file_name}"
#            begin
#                HostUtils.system command
#            rescue HostUtils::CommandFailedError => e
#                raise "Deploy script failed: #{e.message}"
#            end

            activate(deployment_id)

            # Mark new deployment
            @deployments[deployment_id] = OpenStruct.new(:binary => binary,
                                                         :config_path => config_path,
                                                         :core_base => core_base)
            File.open(File.join(@data_dir, deployment_id), "w") do |f|
                f.write(YAML.dump(@deployments[deployment_id]))
            end
        end

        private

        # TODO - make sense with multiple slots?
        def activate number
            core_base = File.join(@deploy_dir, number.to_s)
            current = File.join(@deploy_dir, "current")
            if File.exists? current
                File.unlink(current)
            end
            FileUtils.ln_sf core_base, current
        end

        # Get the build information from gepo
        # It looks for a build.properties files which look like:
        #
        # group=com.ning
        # artifact=metrics.collector
        # version=3.0.0-pre7
        # os=linux
        #
        # We use maven-style coordinates.
        def get_binary_info(config_path)
            build_properties =@repository.get_props(config_path, "build.properties")

            group = build_properties["group"]
            os = build_properties["os"]

            # This is for compatibility reasons with Galaxy pre 4.x.x
            artifact = build_properties["type"] || build_properties["artifact"]
            version = build_properties["build"] || build_properties["version"]
            if build_properties["type"] || build_properties["build"]
                @log.warn("Deprecated fields 'type' or 'build' detected, please use 'artifact' and 'version'")
            end

            OpenStruct.new(:group => group, :artifact => artifact, :version => version, :os => os)
        end

    end
end