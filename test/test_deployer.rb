$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/deployer'
require 'galaxy/host'
require 'helper'
require 'fileutils'
require 'logger'

class TestDeployer < Test::Unit::TestCase
  
  def setup
    @core_package = Tempfile.new("package.tgz").path
    @bad_core_package = Tempfile.new("bad-package.tgz").path
    system %{
      #{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "core_package")} -czf #{@core_package} . 
    }
    system %{
      #{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "bad_core_package")} -czf #{@bad_core_package} . 
    }
    @path = Helper.mk_tmpdir
    @deployer = Galaxy::Deployer.new @path, Logger.new("/dev/null"), "machine", "host"
  end
  
  def test_core_base_is_right    
    core_base = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    assert_equal File.join(@path, "2"), core_base
  end
  
  def test_deployment_dir_is_made
    core_base = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    assert FileTest.directory?(core_base)
  end
  
  def test_xndeploy_exists_after_deployment
    core_base = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    assert FileTest.exists?(File.join(core_base, "bin", "xndeploy"))
  end
  
  def test_xndeploy_invoked_on_deploy
    core_base = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    assert FileTest.exists?(File.join(core_base, "xndeploy_touched_me"))
  end
  
  def test_xndeploy_gets_correct_values
    core_base = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    dump = File.open(File.join(core_base, "xndeploy_touched_me")) do |file|
      Marshal.load file
    end
    assert_equal core_base, dump[:deploy_base]
	  assert_equal "/config", dump[:config_path]
    assert_equal "/repository", dump[:repository]
    assert_equal "/binaries", dump[:binaries_base]
  end
  
  def test_current_symlink_created
    core_base = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    link = File.join(@path, "current")
    assert_equal false, FileTest.symlink?(link)
    @deployer.activate "2"
    assert FileTest.symlink?(link)
    assert_equal File.join(@path, "2"), File.readlink(link)
  end
  
  def test_upgrade
    first = @deployer.deploy "1", @core_package, "/config", "/repository", "/binaries"
    @deployer.activate "1"
    assert_equal File.join(@path, "1"), File.readlink(File.join(@path, "current"))
    
    first = @deployer.deploy "2", @core_package, "/config", "/repository", "/binaries"
    @deployer.activate "2"
    assert_equal File.join(@path, "2"), File.readlink(File.join(@path, "current"))
  end  
  
  def test_bad_archive
    assert_raise RuntimeError do
      @deployer.deploy "bad", "/etc/hosts", "/config", "/repository", "/binaries"
    end
  end
  
  def test_deploy_script_failure
    assert_raise RuntimeError do
      @deployer.deploy "bad", @bad_core_package, "/config", "/repository", "/binaries"
    end
  end
end
