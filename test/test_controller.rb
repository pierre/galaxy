require 'test/unit'
require 'galaxy/controller'
require 'galaxy/deployer'
require 'galaxy/host'
require 'galaxy/db'
require 'galaxy/slotinfo'
require 'helper'
require 'fileutils'
require 'logger'

class TestController < Test::Unit::TestCase
  
  def setup
    @core_package = Tempfile.new("package.tgz").path
    system %{
      #{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "core_package")} -czf #{@core_package} . 
    }
    # Hack the environment to allow the spawned scripts to find galaxy/scripts
    ENV["RUBYLIB"] =  File.join(File.dirname(__FILE__), "..", "lib")
    @path = Helper.mk_tmpdir
    @db = Galaxy::DB.new @path
    log = Logger.new("/dev/null")
    current_number = 1
    config ="/env/version/type"

    @slot_info = Galaxy::SlotInfo.new @db, "http://repository/base", "http://binaries/base", log, "machine", "slot", "group"

    @deployer = Galaxy::Deployer.new "http://repository/base", "http://binaries/base", @path, log, @slot_info
    @slot_info.update config, @deployer.core_base_for(current_number)
    @core_base = @deployer.deploy current_number, @core_package, config
    @controller = Galaxy::Controller.new @slot_info, @core_base, log

    # Hack the environment to allow the spawned scripts to find galaxy/scripts
    ENV["RUBYLIB"] =  File.join(File.dirname(__FILE__), "..", "lib")
  end
  
  def test_perform_success
    output = @controller.perform!('test-success')
    assert_equal "gorple\n", output
  end
  
  def test_perform_failure
    assert_raise Galaxy::Controller::CommandFailedException do
      @controller.perform!('test-failure')
    end
  end
  
  def test_perform_unrecognized
    assert_raise Galaxy::Controller::UnrecognizedCommandException do
      @controller.perform!('unrecognized')
    end
  end
  
  def test_controller_arguments
    assert_nothing_raised do
      @controller.perform!('test-arguments')
    end
  end

end
