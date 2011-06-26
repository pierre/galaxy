require 'test/unit'
require 'galaxy/controller'
require 'galaxy/deployer'
require 'galaxy/host'
require 'galaxy/db'
require 'helper'
require 'fileutils'
require 'logger'
require 'galaxy/slotinfo'

class TestSlotInfo < Test::Unit::TestCase
  
  def setup
    @core_package = Tempfile.new("package.tgz").path
    system %{
      #{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "core_package")} -czf #{@core_package} . 
    }
    # Hack the environment to allow the spawned scripts to find galaxy/scripts
    ENV["RUBYLIB"] =  File.join(File.dirname(__FILE__), "..", "lib")

    log = Logger.new("/dev/null")
    @path = Helper.mk_tmpdir
    @db = Galaxy::DB.new @path

    @slot_environment = OpenStruct.new(
                                       :test1 => "value1",
                                       :test2 => "value2",
                                       :test3 => 4815)

    @slot_info = Galaxy::SlotInfo.new @db, "/repository", "/binaries", log, "machine", "slot", "group", @slot_environment
    current_number = 1
    config = "/env/version/type"
    @deployer = Galaxy::Deployer.new "/repository", "/binaries", @path, log, @slot_info

    @slot_info.update config, @deployer.core_base_for(current_number)
    @core_base = @deployer.deploy current_number, @core_package, config

    @controller = Galaxy::Controller.new @slot_info, @core_base, log
  end
  
  def test_slot_info
    assert_nothing_raised do
      @controller.perform!('test-slot-info')
    end
  end

end
