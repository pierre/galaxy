require 'ostruct'
require 'yaml'

module Galaxy
  class SlotInfo
    def initialize db, repository_base, binaries_base, log, machine, agent_id, agent_group, slot_environment = nil
      @db = db
      @repository_base = repository_base
      @binaries_base = binaries_base
      @log = log
      @machine = machine
      @agent_id = agent_id
      @agent_group = agent_group
      @slot_environment = slot_environment
    end

    # Writes the current state of the world into the 
    # slot_info file. 
    def update config_path, core_base
      slot_info = OpenStruct.new(:base =>         core_base,
                                 :config_path => config_path,
                                 :repository =>  @repository_base,
                                 :binaries =>    @binaries_base,
                                 :machine =>     @machine,
                                 :agent_id =>    @agent_id,
                                 :agent_group => @agent_group,
                                 :env =>          @slot_environment)

      @log.debug "Slot Info now #{slot_info}"
      @db['slot_info'] = YAML.dump slot_info
    end

    def get_file_name
      @db.file_for('slot_info')
    end
  end
end



