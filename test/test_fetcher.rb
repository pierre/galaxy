require 'test/unit'
require 'galaxy/fetcher'
require 'helper'
require 'fileutils'
require 'logger'
require 'webrick'
include WEBrick

class TestFetcher < Test::Unit::TestCase

  class FetchObj
    attr_reader :group, :artifact, :version;

    def initialize group, artifact, version
      @group = group
      @artifact = artifact
      @version = version
    end
  end

  def setup
    @local_fetcher = Galaxy::Fetcher.new(File.join(File.dirname(__FILE__), "property_data"), nil, nil, Logger.new("/dev/null"))
    @http_fetcher = Galaxy::Fetcher.new("http://localhost:7777", nil, nil, Logger.new("/dev/null"))

    webrick_logger =  Logger.new(STDOUT)
    webrick_logger.level = Logger::WARN
    @server = HTTPServer.new(:Port => 7777, :Logger => webrick_logger)
    @server.mount("/", HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), "property_data"), true)
    Thread.start do
      @server.start
    end
  end

  def teardown
    @server.shutdown
  end
    
  def test_local_fetch
    obj = FetchObj.new nil, "foo", "bar"
    path = @local_fetcher.fetch obj, nil, "properties"
    assert File.exists?(path)
  end
  
  def test_http_fetch

    obj = FetchObj.new nil, "foo", "bar"
    path = @http_fetcher.fetch obj, nil, "properties"
    assert File.exists?(path)
  end

  def test_http_fetch_not_found
    assert_raise RuntimeError do
      @server.logger.level = Logger::FATAL
      obj = FetchObj.new nil, "gorple", "fez"
      path = @http_fetcher.fetch obj, nil, "properties"
      @server.logger.level = Logger::WARN
    end
  end

  def test_http_group_fetch

     obj = FetchObj.new "some.domain", "foo", "bar"
     path = @http_fetcher.fetch obj, nil, "properties"
     assert File.exists?(path)
   end

   def test_http_group_fetch_not_found
     assert_raise RuntimeError do
       @server.logger.level = Logger::FATAL
       obj = FetchObj.new "some.domain", "gorple", "fez"
       path = @http_fetcher.fetch obj, nil, "properties"
       @server.logger.level = Logger::WARN
     end
   end
end
