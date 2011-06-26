require 'optparse'
require 'yaml'
require 'ostruct'

require 'galaxy/repository'

#
# Support module for xndeploy, control etc. to make writing these scripts easier.
#
module Galaxy
  class ScriptSupport
    attr_accessor :base, :config_path, :repository, :binaries, :machine, :agent_id, :agent_group
    attr_reader :rest, :slot_info, :env


    def initialize args, & block

      @rest = OptionParser.new do |opts|
        opts.on("--slot-info SLOT_INFO") { |arg| @slot_info = arg }
        yield opts if block_given?
      end.parse! args

      raise "No slot info file given" if @slot_info.nil?

      @slot_data = load_slot_info

      @base = @slot_data.base
      @config_path = @slot_data.config_path
      @repository = @slot_data.repository
      @binaries = @slot_data.binaries
      @machine = @slot_data.machine
      @agent_id = @slot_data.agent_id
      @agent_group = @slot_data.agent_group
      @env = @slot_data.env
      # Wrap @env in an OpenStruct unless it already is one to allow lookups by key name using "."
      @env = OpenStruct.new(@slot_data.env) unless @env.is_a? OpenStruct

      raise "No base given"           if @slot_data.base.nil?
      raise "No config path given"    if @slot_data.config_path.nil?
      raise "No repository url given" if @slot_data.repository.nil?
      raise "No binaries url given"   if @slot_data.binaries.nil?
      raise "No machine given"        if @slot_data.machine.nil?
      raise "No agent id given"       if @slot_data.agent_id.nil?
      raise "No agent group given"    if @slot_data.agent_group.nil?
      raise "No environment given"    if @slot_data.env.nil?
    end

    def load_slot_info
      unless @slot_info.nil? 
        begin
          File.open @slot_info, "r" do |f|
            content = f.read
            data = YAML.load(content)
            if data.is_a? OpenStruct

              # Fix up the environment if it was not set by the caller
              if data.env.nil?
                data.env = OpenStruct.new
              end
              return data
            end
            puts "Expected a serialized OpenStruct, found something else!"
          end
        rescue Errno::ENOENT
        end
      end
      return OpenStruct.new(:env => OpenStruct.new)
    end

    # This splits /env/version/type into "" "env" "version" "type". So the values are 1-3, not 0-2.
    def config
      config = config_path.split("/")
      unless config.length == 4
        raise "Invalid configuration path: #{config_path}"
      end
      config
    end
    
    # Hard coded!. Sucks! Needs fixing!
    def config_location
      config_location = File.join(base, "config")
    end
    
    def get_slot_variables
      information = {}
      
      information["deploy.env"]          = config[1]
      information["deploy.version"]      = config[2]
      information["deploy.type"]         = config[3]
      information["deploy.config"]       = config_path
      
      information["env.base"]            = base
      information["env.repository"]      = repository
      information["env.binaries"]        = binaries
      information["env.agent_id"]        = agent_id
      information["env.agent_group"]     = agent_group
      information["env.machine"]         = machine
      information["env.slot_info"]       = slot_info
      information["env.config_location"] = config_location

      information["internal.ip"]         = env.internal_ip
      information["internal.port.http"]  = env.internal_http   || 80
      information["internal.port.https"] = env.internal_https  || 443
      
      information["external.ip"]         = env.external_ip
      information["external.port.http"]  = env.external_http   || 80
      information["external.port.https"] = env.external_https  || 443
      
      information["private.port.jmx"]    = env.private_port_jmx || 12345
      information["private.port.tomcat"] = env.private_port_tomcat || 8005
      
      information["private.port.0"]      = env.private_port_0   || 28800
      information["private.port.1"]      = env.private_port_1   || 28801
      information["private.port.2"]      = env.private_port_2   || 28802
      information["private.port.3"]      = env.private_port_3   || 28803
      information["private.port.4"]      = env.private_port_4   || 28804
      
      information["global.port.0"]       = env.global_port_0   || 28805
      information["global.port.1"]       = env.global_port_1   || 28806
      information["global.port.2"]       = env.global_port_2   || 28807
      information["global.port.3"]       = env.global_port_3   || 28808
      information["global.port.4"]       = env.global_port_4   || 28809
      
      information
    end

    def get_java_galaxy_env
      information = get_slot_variables

      information_opts = []
      information.each { |key, value| 
        if value.nil?
          information_opts << "-Dgalaxy.#{key}"
        else
          information_opts << "-Dgalaxy.#{key}=#{value}"
        end
      }

      information_opts
    end

    def get_jvm_opts
      repository =   Galaxy::Repository.new config_location
      jvm_files = repository.walk(config_path, 'jvm.properties')
      jvm_lines = {}

      jvm_files.each do |lines|
        lines.each do |line|
          unless line =~ /^\s*\#/
            line.split(' ').each do |element|
              key,*values = element.split("=")
              jvm_lines[key.strip] = (values.length == 0) ? nil : values.join("=").strip
            end
          end
        end
      end

      jvm_opts = []

      jvm_lines.each { |key, value| 
        if value.nil?
          jvm_opts << "#{key}"
        else
          jvm_opts << "#{key}=#{value}"
        end
      }

      jvm_opts
    end

  end
end

