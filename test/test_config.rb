$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/config'
require 'galaxy/log'
require 'helper'
require 'ostruct'
require 'stringio'
require 'logger'

class TestConfig < Test::Unit::TestCase

  def setup
    @path = Helper.mk_tmpdir
    @file = File.join(@path, "foo")
    File.open @file, "w" do |file| 
      file.print "foo: bar\n"
    end
    # Make sure not to pick up the local /etc/galaxy.conf
    @s = OpenStruct.new(:config_file => @file)
    @c = Galaxy::AgentConfigurator.new @s
    @c2 = Galaxy::ConsoleConfigurator.new @s
  end

  def test_unknown_agent_id
    assert_equal "unset", @c.agent_id
  end

  def test_unknown_agent_group
    assert_equal "unknown", @c.agent_group
  end

  def test_logging
    Galaxy::HostUtils.logger("fred").info "boo!"
    Galaxy::HostUtils.logger("fred").info "warn!"
  end

  def test_data_dir
    assert_equal "#{Galaxy::HostUtils.avail_path}/galaxy-agent/data" , @c.data_dir
  end

  def test_deploy_dir
    assert_equal "#{Galaxy::HostUtils.avail_path}/galaxy-agent/deploy" , @c.deploy_dir
  end

  def test_deploy_dir_specced
    @s.deploy_dir = "/tmp/plop"
    assert_equal "/tmp/plop", @c.deploy_dir
  end

  def test_data_dir_specced
    @s.data_dir = "/tmp/plop"
    assert_equal "/tmp/plop", @c.data_dir
  end

  def test_verbose
    @s.verbose = true
    assert @c.configure[:verbose]
  end

  def test_log_level_debug
    @s.log_level = "DEBUG"
    assert_equal Logger::DEBUG, @c.configure[:log_level]
  end

  def test_log_level_info
    @s.log_level = "INFO"
    assert_equal Logger::INFO, @c.configure[:log_level]
  end

  def test_log_level_warn
    @s.log_level = "WARN"
    assert_equal Logger::WARN, @c.configure[:log_level]
  end

  def test_log_level_error
    @s.log_level = "ERROR"
    assert_equal Logger::ERROR, @c.configure[:log_level]
  end

  def test_log_level_other
    @s.log_level = "---UNK"
    assert_equal nil, @c.configure[:log_level]
  end
end
