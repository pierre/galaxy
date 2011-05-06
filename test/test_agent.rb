require 'test/unit'
require 'galaxy/transport'
require 'galaxy/agent'
require 'galaxy/host'
require 'webrick'
require 'thread'
require 'timeout'
require 'helper'
require 'fileutils'
require 'logger'

class TestAgent < Test::Unit::TestCase

  def setup
    @tempdir = Helper.mk_tmpdir

    @data_dir = File.join(@tempdir, 'data')
    @deploy_dir = File.join(@tempdir, 'deploy')
    @binaries_base = File.join(@tempdir, 'binaries')

    FileUtils.mkdir_p @data_dir
    FileUtils.mkdir_p @deploy_dir
    FileUtils.mkdir_p @binaries_base

    system "#{Galaxy::HostUtils.tar} -C #{File.join(File.dirname(__FILE__), "core_package")} -czf #{@binaries_base}/test-1.0-12345.tar.gz ."

    # Hack the environment to allow the spawned scripts to find galaxy/scripts
    ENV["RUBYLIB"] =  File.join(File.dirname(__FILE__), "..", "lib")

    webrick_logger =  Logger.new(STDOUT)
    webrick_logger.level = Logger::WARN
    @server = WEBrick::HTTPServer.new(:Port => 8000, :Logger => webrick_logger)

    # Replies on POST from agent
    @server.mount_proc("/") do |request, response|
        status, content_type, body = 200, "text/plain", "pong"
        response.status = status
        response['Content-Type'] = content_type
        response.body = body
    end
    @server.mount("/config", WEBrick::HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), "property_data"), true)
    @server.mount("/binaries", WEBrick::HTTPServlet::FileHandler, @binaries_base, true)

    Thread.start do
      @server.start
    end

    # Note: force 127.0.0.1 not to rely on `hostname` and localhost
    @agent = Galaxy::Agent.start({:repository => File.dirname(__FILE__) + "/property_data",
                                  :binaries => @binaries_base,
                                  :data_dir => @data_dir,
                                  :deploy_dir => @deploy_dir,
                                  :log_level => Logger::WARN,
                                  :agent_url => "druby://127.0.0.1:4441",
                                  :console => "http://127.0.0.1:8000",
                                  :agent_id => "test_agent",
                                  :agent_group => "test_group"
                                  })
  end

  def teardown
    @agent.shutdown
    @server.shutdown
    FileUtils.rm_rf @tempdir
  end

  def test_agent_assign
    @agent.become! '/a/b/c'
    assert File.exist?(File.join(@deploy_dir, 'current', 'bin'))
  end

  def test_agent_perform
    @agent.become! '/a/b/c'
    assert_nothing_raised do
      @agent.perform! 'test-success'
    end
  end

  def test_agent_perform_failure
    @agent.become! '/a/b/c'
    assert_raise RuntimeError do
      @agent.logger.log.level = Logger::FATAL
      # The failure will spit a stacktrace in the log (ERROR)
      @agent.perform! 'test-failure'
      @agent.logger.log.level = Logger::WARN
    end
  end
end
