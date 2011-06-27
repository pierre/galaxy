require 'test/unit'
require 'galaxy/software'
require 'galaxy/log'
require 'galaxy/properties'

class TestBuildProperties < Test::Unit::TestCase

  def setup
    @logger = Logger.new("/dev/null")
    @config = Galaxy::SoftwareConfiguration.new_from_config_path("/a/b/c")
  end

  def test_simple_build_properties
    build_properties=Galaxy::BuildProperties.new "some.group", "some-artifact", "2.0", nil, @config.config_path

    assert build_properties.group == "some.group"
    assert build_properties.artifact == "some-artifact"
    assert build_properties.version == "2.0"
    assert build_properties.os.nil?
    assert build_properties.config_path == "/a/b/c"
  end

  def test_with_group_old_props
    builder = Galaxy::Properties::Builder.new File.dirname(__FILE__) + "/build_props/old_group", nil, nil, @logger
    build_properties=Galaxy::BuildProperties.new_from_config @logger, builder, @config

    assert build_properties.group == "some.group"
    assert build_properties.artifact == "old-some-artifact"
    assert build_properties.version == "2.0"
    assert build_properties.os.nil?
    assert build_properties.config_path == "/a/b/c"
  end

  def test_without_group_old_props
    builder = Galaxy::Properties::Builder.new File.dirname(__FILE__) + "/build_props/old_no_group", nil, nil, @logger
    build_properties=Galaxy::BuildProperties.new_from_config @logger, builder, @config

    assert build_properties.group.nil?
    assert build_properties.artifact == "old-some-artifact"
    assert build_properties.version == "3.0"
    assert build_properties.os.nil?
    assert build_properties.config_path == "/a/b/c"
  end

  def test_with_group
    builder = Galaxy::Properties::Builder.new File.dirname(__FILE__) + "/build_props/group", nil, nil, @logger
    build_properties=Galaxy::BuildProperties.new_from_config @logger, builder, @config

    assert build_properties.group == "some.group"
    assert build_properties.artifact == "new-some-artifact"
    assert build_properties.version == "2.0"
    assert build_properties.os.nil?
    assert build_properties.config_path == "/a/b/c"
  end

  def test_without_group
    builder = Galaxy::Properties::Builder.new File.dirname(__FILE__) + "/build_props/no_group", nil, nil, @logger
    build_properties=Galaxy::BuildProperties.new_from_config @logger, builder, @config

    assert build_properties.group.nil?
    assert build_properties.artifact == "new-some-artifact"
    assert build_properties.version == "3.0"
    assert build_properties.os.nil?
    assert build_properties.config_path == "/a/b/c"
  end
end
