require 'test/unit'
require 'galaxy/deployer'
require 'galaxy/host'
require 'galaxy/db'
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
    @db = Galaxy::DB.new @path
    log = Logger.new("/dev/null")
    @config = "/env/version/type"
    @slot_info = Galaxy::SlotInfo.new @db, "/repository", "/binaries", log, "machine", "slot", "group"

    @deployer = Galaxy::Deployer.new "/repository", "/binaries", @path, log, @slot_info

    # Hack the environment to allow the spawned scripts to find galaxy/scripts
    ENV["RUBYLIB"] =  File.join(File.dirname(__FILE__), "..", "lib")
  end
  
  def test_core_base_is_right    
    @slot_info.update @config, @deployer.core_base_for(2)
    core_base = @deployer.deploy "2", @core_package, @config
    assert_equal File.join(@path, "2"), core_base
  end
  
  def test_deployment_dir_is_made
    @slot_info.update @config, @deployer.core_base_for(2)
    core_base = @deployer.deploy "2", @core_package, @config
    assert FileTest.directory?(core_base)
  end
  
  def test_xndeploy_exists_after_deployment
    @slot_info.update @config, @deployer.core_base_for(2)
    core_base = @deployer.deploy "2", @core_package, @config
    assert FileTest.exists?(File.join(core_base, "bin", "xndeploy"))
  end
  
  def test_xndeploy_invoked_on_deploy
    @slot_info.update @config, @deployer.core_base_for(2)
    core_base = @deployer.deploy "2", @core_package, @config
    assert FileTest.exists?(File.join(core_base, "xndeploy_touched_me"))
  end
  
  def test_xndeploy_gets_correct_values
    @slot_info.update @config, @deployer.core_base_for(2)
    core_base = @deployer.deploy "2", @core_package, @config
    dump = File.open(File.join(core_base, "xndeploy_touched_me")) do |file|
      Marshal.load file
    end
    assert_equal core_base, dump[:deploy_base]
	  assert_equal @config, dump[:config_path]
    assert_equal "/repository", dump[:repository]
    assert_equal "/binaries", dump[:binaries_base]
  end
  
  def test_current_symlink_created
    @slot_info.update @config, @deployer.core_base_for(2)
    core_base = @deployer.deploy "2", @core_package, @config
    link = File.join(@path, "current")
    assert_equal false, FileTest.symlink?(link)
    @deployer.activate "2"
    assert FileTest.symlink?(link)
    assert_equal File.join(@path, "2"), File.readlink(link)
  end
  
  def test_upgrade
    @slot_info.update @config, @deployer.core_base_for(1)
    first = @deployer.deploy "1", @core_package, @config
    @deployer.activate "1"
    assert_equal File.join(@path, "1"), File.readlink(File.join(@path, "current"))
    
    @slot_info.update @config, @deployer.core_base_for(2)
    first = @deployer.deploy "2", @core_package, @config
    @deployer.activate "2"
    assert_equal File.join(@path, "2"), File.readlink(File.join(@path, "current"))
  end  
  
  def test_bad_archive
    assert_raise RuntimeError do
      @slot_info.update @config, @deployer.core_base_for("bad")
      @deployer.deploy "bad", "/etc/hosts", @config
    end
  end
  
  def test_deploy_script_failure
    assert_raise RuntimeError do
      @slot_info.update @config, @deployer.core_base_for("bad")
      @deployer.deploy "bad", @bad_core_package, @config
    end
  end
end
