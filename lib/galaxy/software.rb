module Galaxy
    class SoftwareConfiguration
        attr_accessor :environment, :version, :type

        def initialize environment, version, type
            @environment = environment
            @version = version
            @type = type
        end

        def config_path
            "/#{environment}/#{version}/#{type}"
        end

        def self.new_from_config_path config_path
            # Using ! as regex delimiter since the config path contains / characters
            unless components = %r!^/([^/]+)/([^/]+)/(.*)$!.match(config_path)
                raise "Illegal config path '#{config_path}'"
            end
            environment, version, type = components[1], components[2], components[3]
            new environment, version, type
        end
    end

    class SoftwareDeployment
        attr_accessor :executable, :config, :running_state

        def initialize executable, config, running_state
          @executable = executable
            @config = config
            @running_state = running_state
        end
    end

    class BuildProperties
      attr_reader :group, :artifact, :version, :os, :config_path

      def initialize group, artifact, version, os, config_path

        if artifact.nil?
          error_reason = "Cannot determine artifact type for #{config_path}"
          raise error_reason
        end

        if version.nil?
          error_reason = "Cannot determine version for #{config_path}"
          raise error_reason
        end

        @group = group
        @artifact = artifact
        @version = version
        @os = os
        @config_path = config_path
      end

      def validate_os os
        if @os and @os != os
          error_reason = "#{@config_path} contains a different OS architecture: #{os}, host requires #{@os}."
          raise error_reason
        end
      end

      def self.new_from_config logger, prop_builder, config
        build_properties = prop_builder.build(config.config_path, "build.properties")

        group = build_properties['group']
        artifact = build_properties['type'] || build_properties['artifact']
        version = build_properties['build'] || build_properties['version']

        if build_properties['type'] || build_properties['build']
          logger.warn("Deprecated fields 'type' or 'build' detected, please use 'artifact' and 'version'")
        end

        os = build_properties['os']
        new group, artifact, version, os, config.config_path
      end
    end

    class BuildVersion
      attr_reader :group, :artifact, :version

      def initialize group, artifact, version
        if artifact.nil?
          error_reason = "Cannot determine artifact type for #{config_path}"
          raise error_reason
        end

        if version.nil?
          error_reason = "Cannot determine version for #{config_path}"
          raise error_reason
        end

        @group = group
        @artifact = artifact
        @version = version
      end

      def self.new_from_options build_version
        if !build_version.nil?
          elements = build_version.split ':'
          if elements.size == 2
            group = nil
            artifact = elements[0]
            version = elements[1]
          elsif elements.size == 3
            group = elements[0]
            artifact = elements[1]
            version = elements[2]
          else
            error_reason = "bad version identifier: #{build_version}"
            raise error_reason
          end

          if artifact.nil?
            error_reason = "Artifact version can not be empty!"
            raise error_reason
          end

          if version.nil?
            error_reason = "Version version can not be empty!"
            raise error_reason
          end

          new group, artifact, version
        end
      end
    end
end
