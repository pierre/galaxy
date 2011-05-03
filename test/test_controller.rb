$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/controller'
require 'galaxy/deployer'
require 'galaxy/host'
require 'helper'
require 'fileutils'
require 'logger'

class TestController < Test::Unit::TestCase
  
  def setup
    @core_package = Tempfile.new("package.tgz").path
    system %{
      #{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "core_package")} -czf #{@core_package} . 
    }
    @path = Helper.mk_tmpdir
    @deployer = Galaxy::Deployer.new @path, Logger.new("/dev/null"), "machine", "slot", "group"
    @core_base = @deployer.deploy "1", @core_package, "/config", "/repository", "/binaries"
    @controller = Galaxy::Controller.new @core_base, '/config/path', 'http://repository/base', 'http://binaries/base', Logger.new("/dev/null"), "machine", "slot", "group"
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
