require 'optparse'
require 'yaml'
require 'ostruct'

#
# Support module for xndeploy, control etc. to make writing these scripts easier.
#
module Galaxy
  class ScriptSupport
    def initialize args

      @rest = OptionParser.new do |opts|
        opts.on("--slot-info SLOT_INFO") { |arg| @slot_info = arg }
      end.parse! args

      raise "No slot info file given" if @slot_info.nil?

      @slot_data = load_slot_info

      raise "No base given" if @slot_data.base.nil?
      raise "No config path given" if @slot_data.config_path.nil?
      raise "No repository url given" if @slot_data.repository.nil?
      raise "No binaries url given" if @slot_data.binaries.nil?
      raise "No machine given" if @slot_data.machine.nil?
      raise "No agent id given" if @slot_data.agent_id.nil?
      raise "No agent group given" if @slot_data.agent_group.nil?
      raise "No environment given" if @slot_data.env.nil?
    end

    def load_slot_info
      unless @slot_info.nil? 
        begin
          File.open @slot_info, "r" do |f|
            data = YAML.load(f.read)
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

    # Remainder of the command line arguments
    def rest
      @rest
    end

    def base
      @slot_data.base
    end

    def config_path
      @slot_data.config_path
    end

    def repository
      @slot_data.repository
    end

    def binaries
      @slot_data.binaries
    end

    def machine
      @slot_data.machine
    end

    def agent_id
      @slot_data.agent_id
    end

    def agent_group
      @slot_data.agent_group
    end

    def env
      @slot_data.env
    end
  end
end

