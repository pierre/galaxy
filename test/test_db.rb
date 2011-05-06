require 'test/unit'
require 'galaxy/db'
require 'helper'

class TestDB < Test::Unit::TestCase

  def setup
    @db = Galaxy::DB.new "#{Helper.mk_tmpdir}/galaxy.db"
  end
  
  def test_silly
    @db["k"] = "v"
    assert_equal "v", @db["k"]
  end
  
  def test_in_child
    @db["name"] = "Fred"
    pid = fork do
      if @db["name"] == "Fred"
        exit 0
      else
        exit 1
      end
    end
    _, status = Process.waitpid2 pid
    assert_equal 0, status.exitstatus
  end
  
  
  
end
