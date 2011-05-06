require "fileutils"
require "test/unit"
require "galaxy/host"

class TestHost < Test::Unit::TestCase
  
  def test_tar_executable_was_found
    assert_not_nil Galaxy::HostUtils.tar
  end
  
  def test_system_success
    assert_nothing_raised do
      Galaxy::HostUtils.system 'true'
    end
  end
  
  def test_system_failure
    assert_raise Galaxy::HostUtils::CommandFailedError do
      Galaxy::HostUtils.system 'false'
    end
  end
  
  def test_system_failure_output
    begin
      Galaxy::HostUtils.system 'ls /gorple/fez'
    rescue Exception => e
      assert_match(/No such file or directory/, e.message)
    end
  end
end
