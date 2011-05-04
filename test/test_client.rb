$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/agent'
require 'galaxy/command'
require 'galaxy/console'
require 'logger'
require 'helper'

class TestClient < Test::Unit::TestCase

  def setup
    @path = Helper.mk_tmpdir
    @file = File.join(@path, "foo")
    File.open @file, "w" do |file| 
      file.print "foo: bar\n"
    end
    @galaxy = "ruby -Ilib bin/galaxy -C #{@file}"
  end

  ENV.delete 'GALAXY_CONSOLE'

  Galaxy::Commands.each do |command|
    define_method "test_#{command}_usage" do
      output = `#{@galaxy} -h #{command} 2>&1`
      assert_match("Usage for '#{command}':", output)
    end
  end

  def test_usage_with_no_arguments
    output = `#{@galaxy} 2>&1`
    assert_match("Error: Missing command", output)
  end

  def test_show_with_no_console
    output = `#{@galaxy} show 2>&1`
    assert_match("Error: Cannot determine console host", output)
  end

  def test_show_console
    console = Galaxy::Console.start({ :host => 'localhost' })
    begin
      output = `#{@galaxy} show-console -c localhost 2>&1`
      assert_match("druby://localhost:4440\thttp://localhost:4442\tlocalhost\t-\t5\n", output)
    ensure
      console.shutdown unless console.nil?
    end
  end

  def test_show_with_console_from_environment
#    console = Galaxy::Console.start({ :host => 'localhost' })
#    output = `GALAXY_CONSOLE=localhost #{@galaxy} show 2>&1`
#    assert_match("No agents matching the provided filter(s) were available for show", output)
#    console.shutdown
  end

  def test_show_with_console_from_command_line
#    console = Galaxy::Console.start({ :host => 'localhost' })
#    output = `#{@galaxy} -c localhost show 2>&1`
#    assert_match("No agents matching the provided filter(s) were available for show", output)
#    console.shutdown
  end

  def test_show_with_bad_console
    output = `#{@galaxy} -c non-existent-host show 2>&1`
    # On Linux, this will be: 
    #              Error: druby://non-existent-host:4440 - #<SocketError: getaddrinfo: Name or service not known>"
    #assert_match("Error: druby://non-existent-host:4440 - #<SocketError: getaddrinfo: nodename nor servname provided, or not known", output)
    assert (output =~ /SocketError/)
  end

  def test_show_with_one_agent
    console = Galaxy::Console.start({ :host => 'localhost', :log_level => Logger::WARN })
    begin
      agent = Galaxy::Agent.start({ :url => 'druby://localhost:4440', :agent_id => "test_agent", :agent_group => "test_group", :console => 'localhost', :log_level => Logger::WARN })
      begin
        output = `#{@galaxy} -c localhost show -i localhost 2>&1`.split("\n")
        assert_equal(1, output.length)
        assert_match("No agents matching the provided filter(s) were available for show", output[0])
      ensure
        agent.shutdown unless agent.nil?
      end
    ensure
      console.shutdown unless console.nil?
    end
  end
end
