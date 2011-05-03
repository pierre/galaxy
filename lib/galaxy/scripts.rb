require 'optparse'
require 'yaml'
require 'ostruct'

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
        yield self if block_given?
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

      raise "No base given"           if base.nil?
      raise "No config path given"    if config_path.nil?
      raise "No repository url given" if repository.nil?
      raise "No binaries url given"   if binaries.nil?
      raise "No machine given"        if machine.nil?
      raise "No agent id given"       if agent_id.nil?
      raise "No agent group given"    if agent_group.nil?
      raise "No environment given"    if env.nil?
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
  end
end

