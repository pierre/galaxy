$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require "galaxy/properties"
require 'logger'

class TestPropertyBuilder < Test::Unit::TestCase

  PropertyBase = File.dirname(__FILE__) + "/property_data"
  
  def setup
    @builder = Galaxy::Properties::Builder.new PropertyBase, Logger.new("/dev/null")
  end
  
  def test_simple
    props = @builder.build "/a/b/c/d", "test_simple.properties"
    assert_equal "green", props['chris']
  end
  
  def test_override
    props = @builder.build "/a/b/c/d", "test_override.properties"
    assert_equal "purple", props['oscar']
    assert_equal "red", props['sam']
  end

  def test_comments_ignored
    props = @builder.build "/a/b/c/d", "test_comments_ignored.properties"

    assert_nil props['hello']
    assert_nil props['#hello']
    assert_equal "fuschia", props['red']
  end

end
