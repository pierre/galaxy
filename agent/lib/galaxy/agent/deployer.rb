require 'yaml'

require File.expand_path(File.join(Galaxy::Agent::BASE, 'fetcher'))
require File.expand_path(File.join(Galaxy::Agent::BASE, 'host'))
require File.expand_path(File.join(Galaxy::Agent::BASE, 'repository'))

module Galaxy::Agent
    # @Singleton
    class Deployer
        attr_reader :deployments

        def initialize(log, config_repo, binaries_repo, deploy_dir, data_dir, http_user=nil, http_password=nil, slot_info_path=nil)
            @log = log
            @config_repo = config_repo
            @binaries_repo = binaries_repo
            @deploy_dir = deploy_dir
            @data_dir = data_dir
            @slot_info_path = slot_info_path

            # Downloader for configs
            @repository = Repository.new(@config_repo)

            # Downloader for binaries
            @fetcher = Fetcher.new(@log, @binaries_repo, http_user, http_password)

            # Internal state of deployments - dumped to disk
            @deployments = {}
        end

        def deploy(config_path)
            # Validate the config path (of the form /env/version/build)
            # Using ! as regex delimiter since the config path contains / characters
            unless %r!^/([^/]+)/([^/]+)/(.*)$!.match(config_path)
                raise "Illegal config path '#{config_path}'"
            end
            # TODO - validate os

            # Create a UUID - we should probably switch to the built-in UUID generator in ruby 1.9
            deployment_id = Time.now.to_i.to_s
            core_base = File.join(@deploy_dir, deployment_id)

            # Install the binary
            binary = install_binary!(config_path, core_base)

            # Perform post-deployment steps
            invoke_post_deployment_script!(config_path, core_base)
            activate(deployment_id)

            # Record new deployment
            @deployments[deployment_id] = OpenStruct.new(:binary => binary,
                                                         :config_path => config_path,
                                                         :core_base => core_base)
            File.open(File.join(@data_dir, deployment_id), "w") do |f|
                f.write(YAML.dump(@deployments[deployment_id]))
            end

            deployment_id
        end

        # Invoke xndeploy
        # See https://github.com/brianm/galaxy-package-spec for semantics
        def invoke_post_deployment_script!(config_path, core_base)
            xndeploy = File.join(core_base, "bin", "xndeploy")
            unless FileTest.executable?(xndeploy)
                xndeploy = "/bin/sh #{xndeploy}"
            end
            # TODO
            #command = "#{xndeploy} --slot-info #{@slot_info_path}"
            command = "#{xndeploy} --base #{core_base} --binaries #{@binaries_repo} --config-path #{config_path} --repository #{@config_repo}"

            output, response_code = HostUtils.system(command)
            raise "Unable invoke xndeploy: #{output}" if response_code != 0
        end

        # Given a config_path (e.g. /qa/15.0/coll) and a
        # core_base (e.g. ~xncore/deploy/10029304), download and install
        # the binary
        # The core_base directory is created if it doesn't exist
        def install_binary!(config_path, core_base)
            # Get binary metadata
            binary = get_binary_info(config_path)
            # Fetch binary
            binary_file = @fetcher.fetch(binary)

            # Unpack the .tar.gz to the correct location
            @log.info("Deploying #{binary} with config #{config_path} to #{core_base}")
            FileUtils.mkdir_p(core_base)
            output, response_code = HostUtils.system("#{HostUtils.tar} -C #{core_base} -zxf #{binary_file.path}")

            # Get rid of the .tar.gz payload
            binary_file.close!

            raise "Unable to untar payload: #{output}" if response_code != 0
            binary
        end

        # TODO - make sense with multiple slots?
        # We keep it for now for backwards compatibility
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
            build_properties = @repository.get_props(config_path, "build.properties")

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