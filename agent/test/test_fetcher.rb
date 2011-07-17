require 'digest/md5'
require 'ostruct'
require 'test/unit'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/agent'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/fetcher'))

class TestFetcher < Test::Unit::TestCase

    BINARIES_PATH = File.join(File.dirname(__FILE__), "/binaries")

    def setup
        @fetcher = Galaxy::Agent::Fetcher.new(BINARIES_PATH, nil, nil, Logger.new(STDOUT, Logger::INFO))
    end

    def test_old_gepo_layout
        build = OpenStruct.new(:artifact => "core", :version => "1.0.1-SNAPSHOT")

        path = @fetcher.construct_binary_path(build)
        assert_equal(File.join(BINARIES_PATH, "core-1.0.1-SNAPSHOT.tar.gz"), path)
    end

    def test_maven_layout
        build = OpenStruct.new(:group => "com.ning", :artifact => "core", :version => "1.0.1-SNAPSHOT")

        path = @fetcher.construct_binary_path(build)
        assert_equal(File.join(BINARIES_PATH, "/com/ning/core/1.0.1-SNAPSHOT/core-1.0.1-SNAPSHOT.tar.gz"), path)
    end

    def test_download
        build = OpenStruct.new(:artifact => "core", :version => "1.0.1-SNAPSHOT")
        file = @fetcher.fetch(build)
        path = file.path

        original_file = Digest::MD5.digest(File.read(File.join(BINARIES_PATH, "core-1.0.1-SNAPSHOT.tar.gz")))
        downloaded_file = Digest::MD5.digest(File.read(file))
        assert_equal(original_file, downloaded_file)

        # Make sure we can delete the file properly
        file.close!
        assert(!File.exists?(path))
    end
end
