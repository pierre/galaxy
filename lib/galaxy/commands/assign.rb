require 'galaxy/report'

module Galaxy
    module Commands
        class AssignCommand < Command
            register_command "assign"
            changes_agent_state

            def initialize args, options
                super

                env, version, type = * args

                raise CommandLineError.new("<env> is missing") unless env
                raise CommandLineError.new("<version> is missing") unless version
                raise CommandLineError.new("<type> is missing") unless type

                @config_path = "/#{env}/#{version}/#{type}"
                @versioning_policy = options[:versioning_policy]
                @build_version = options[:build_version]
                @config_uri = @options[:config_uri]
                @binaries_uri = @options[:binaries_uri]
            end

            def default_filter
                {:set => :empty}
            end

            def execute_for_agent agent
                agent.proxy.become!(@build_version, @config_path, @config_uri, @binaries_uri, @versioning_policy)
            end

            def self.help
                return <<-HELP
#{name}  <env> <version> <type>
        
        Deploy software to the selected hosts
        
        Parameters:
          env      The environment
          version  The software version
          type     The software type
        
        These three parameters together define the configuration path (relative to the repository base):
        
            <repository base>/<env>/<version>/<type>
                HELP
            end
        end
    end
end
