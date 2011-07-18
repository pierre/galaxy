require 'digest/md5'
require 'ostruct'
require 'tmpdir'
require 'test/unit'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/agent'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/deployer'))

class TestFetcher < Test::Unit::TestCase

    GEPO_PATH = File.join(File.dirname(__FILE__), "/gepo")
    BINARIES_PATH = File.join(File.dirname(__FILE__), "/binaries")

    def setup
        @deploy_dir = Dir.mktmpdir
        @data_dir = Dir.mktmpdir
        @deployer = Galaxy::Agent::Deployer.new(Logger.new(STDOUT, Logger::INFO), GEPO_PATH, BINARIES_PATH, @deploy_dir, @data_dir, nil, nil)
    end

    def teardown
        FileUtils.remove_entry_secure(@deploy_dir)
        FileUtils.remove_entry_secure(@data_dir)
    end

    def test_get_binary_info
        binary = @deployer.get_binary_info("/coll")
        assert_nil(binary.group)
        assert_equal("metrics.collector", binary.artifact)
        assert_equal("3.0.0-pre7", binary.version)
        assert_equal("linux", binary.os)
    end

    def test_install_binary
        binary = @deployer.install_binary!("/core", @deploy_dir)

        # Check metadata
        assert_nil(binary.group)
        assert_equal("core", binary.artifact)
        assert_equal("1.0.1-SNAPSHOT", binary.version)
        assert_nil(binary.os)

        # Make sure files were correctly unpacked
        assert(File.exists?(File.join(@deploy_dir, "bin/launcher")))
        assert(File.exists?(File.join(@deploy_dir, "bin/xndeploy")))
        assert(File.exists?(File.join(@deploy_dir, "stuff")))
        assert(!File.exists?(File.join(@deploy_dir, "bleh")))
    end
end
