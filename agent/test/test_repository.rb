require 'test/unit'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/agent'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/repository'))

class TestRepository < Test::Unit::TestCase

    GEPO_PATH = File.join(File.dirname(__FILE__), "/gepo")

    def setup
        @repository = Galaxy::Agent::Repository.new(GEPO_PATH)
    end

    def test_walk
        # Concat the two build.properties
        content = @repository.walk("/coll", "build.properties")
        assert_equal("build=1.0\ntype=metrics.collector\nbuild=3.0.0-pre7\nos=linux", content)
    end

    def test_merge
        # Merge the two build.properties
        content = @repository.get_props("/coll", "build.properties")
        assert_equal({"build"=>"3.0.0-pre7", "type"=>"metrics.collector", "os"=>"linux"}, content)
    end
end
