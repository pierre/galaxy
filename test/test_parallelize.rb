require 'test/unit'
require 'galaxy/parallelize'

class TestParallelize < Test::Unit::TestCase
  def test_parallelize_with_thread_count_of_1
    array = (1..10).entries
    start = Time.new
    array.parallelize(1) { |i| sleep 1 }
    stop = Time.new
    assert stop - start >= 10
    assert stop - start < 11
  end
  
  def test_parallelize_with_thread_count_of_10
    array = (1..100).entries
    start = Time.new
    array.parallelize(10) { |i| sleep 1 }
    stop = Time.new
    assert stop - start >= 10
    assert stop - start < 11
  end
  
  def test_parallelize_with_thread_count_of_100
    array = (1..1000).entries
    start = Time.new
    array.parallelize(100) { |i| sleep 1 }
    stop = Time.new
    assert stop - start >= 10
    assert stop - start < 11
  end
end
