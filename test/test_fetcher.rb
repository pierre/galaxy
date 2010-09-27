$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/fetcher'
require 'helper'
require 'fileutils'
require 'logger'
require 'webrick'
include WEBrick

class TestFetcher < Test::Unit::TestCase

  def setup
    @local_fetcher = Galaxy::Fetcher.new(File.join(File.dirname(__FILE__), "property_data"), Logger.new("/dev/null"))
    @http_fetcher = Galaxy::Fetcher.new("http://localhost:7777", Logger.new("/dev/null"))

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
    path = @local_fetcher.fetch "foo", "bar", "properties"
    assert File.exists?(path)
  end
  
  def test_http_fetch
    path = @http_fetcher.fetch "foo", "bar", "properties"
    assert File.exists?(path)
  end

  def test_http_fetch_not_found
    assert_raise RuntimeError do
      @server.logger.level = Logger::FATAL
      path = @http_fetcher.fetch "gorple", "fez", "properties"
      @server.logger.level = Logger::WARN
    end
  end

end
