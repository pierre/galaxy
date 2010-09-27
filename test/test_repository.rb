$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require "galaxy/repository"

class TestRepository < Test::Unit::TestCase

  PropertyBase = File.dirname(__FILE__) + "/property_data"
  
  def setup
    @builder = Galaxy::Repository.new PropertyBase
  end
  
  def test_simple
    @builder.walk "/a/b/c/d", "test_simple.properties" do |path, content|
      assert_equal "/a/b/c/test_simple.properties", path
    end
  end

  def test_multiple
    paths = []
    @builder.walk "/a/b/c/d", "test_override.properties" do |path, content|
      paths << path
    end
    
    assert_equal ["/a/b/test_override.properties", "/a/b/c/d/test_override.properties"], paths
  end
  
  def test_empty
    paths = []
    @builder.walk "/a/b/c/d", "empty.properties" do |path, content|
      paths << path
    end

    assert_equal [], paths
  end
  
end
