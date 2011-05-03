$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/controller'
require 'galaxy/deployer'
require 'galaxy/host'
require 'galaxy/db'
require 'helper'
require 'fileutils'
require 'logger'

class TestSlotInfo < Test::Unit::TestCase
  
  def setup
    @core_package = Tempfile.new("package.tgz").path
    system %{
      #{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "core_package")} -czf #{@core_package} . 
    }
    # Hack the environment to allow the spawned scripts to find galaxy/scripts
    ENV["RUBYLIB"] =  File.join(File.dirname(__FILE__), "..", "lib")

    @path = Helper.mk_tmpdir
    @db = Galaxy::DB.new @path
    @deployer = Galaxy::Deployer.new @path, Logger.new("/dev/null"), @db, "machine", "slot", "group"
    @core_base = @deployer.deploy "1", @core_package, "/config", "/repository", "/binaries"
    @slot_environment = OpenStruct.new(
                                       :test1 => "value1",
                                       :test2 => "value2",
                                       :test3 => 4815)

    @controller = Galaxy::Controller.new @db, @core_base, '/config/path', 'http://repository/base', 'http://binaries/base', Logger.new("/dev/null"), "machine", "slot", "group", @slot_environment
  end
  
  def test_slot_info
    assert_nothing_raised do
      @controller.perform!('test-slot-info')
    end
  end

end
