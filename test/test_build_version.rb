require 'test/unit'
require 'galaxy/software'

class TestBuildVersion < Test::Unit::TestCase

  def test_simple_build_version
    build_version=Galaxy::BuildVersion.new "some.group", "some-artifact", "2.0"

    assert build_version.group == "some.group"
    assert build_version.artifact == "some-artifact"
    assert build_version.version == "2.0"
  end

  def test_with_group
    build_version=Galaxy::BuildVersion.new_from_options "some.group:some-artifact:2.0"

    assert build_version.group == "some.group"
    assert build_version.artifact == "some-artifact"
    assert build_version.version == "2.0"
  end

  def test_without_group
    build_version=Galaxy::BuildVersion.new_from_options "some-artifact:2.0"

    assert build_version.group.nil?
    assert build_version.artifact == "some-artifact"
    assert build_version.version == "2.0"
  end
end
