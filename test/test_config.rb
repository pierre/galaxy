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
    @c2 = Galaxy::ConsoleConfigurator.new @s
  end

  def test_logging
    Galaxy::HostUtils.logger("fred").info "boo!"
    Galaxy::HostUtils.logger("fred").info "warn!"
  end
end
