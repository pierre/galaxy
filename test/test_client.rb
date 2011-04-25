$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/agent'
require 'galaxy/command'
require 'galaxy/console'
require 'logger'

class TestClient < Test::Unit::TestCase

  ENV.delete 'GALAXY_CONSOLE'
  GALAXY = "ruby -Ilib bin/galaxy"

  Galaxy::Commands.each do |command|
    define_method "test_#{command}_usage" do
      output = `#{GALAXY} -h #{command} 2>&1`
      assert_match("Usage for '#{command}':", output)
    end
  end

  def test_usage_with_no_arguments
    output = `#{GALAXY} 2>&1`
    assert_match("Error: Missing command", output)
  end

  def test_show_with_no_console
    output = `#{GALAXY} show 2>&1`
    assert_match("Error: Cannot determine console host", output)
  end

  def test_show_console
    console = Galaxy::Console.start({ :host => 'localhost' })
    begin
      output = `#{GALAXY} show-console -c localhost 2>&1`
      assert_match("druby://localhost:4440\thttp://localhost:4442\tlocalhost\t-\t5\n", output)
    ensure
      console.shutdown unless console.nil?
    end
  end

  def test_show_with_console_from_environment
#    console = Galaxy::Console.start({ :host => 'localhost' })
#    output = `GALAXY_CONSOLE=localhost #{GALAXY} show 2>&1`
#    assert_match("No agents matching the provided filter(s) were available for show", output)
#    console.shutdown
  end

  def test_show_with_console_from_command_line
#    console = Galaxy::Console.start({ :host => 'localhost' })
#    output = `#{GALAXY} -c localhost show 2>&1`
#    assert_match("No agents matching the provided filter(s) were available for show", output)
#    console.shutdown
  end

  def test_show_with_bad_console
    output = `#{GALAXY} -c non-existent-host show 2>&1`
    # On Linux, this will be: 
    #              Error: druby://non-existent-host:4440 - #<SocketError: getaddrinfo: Name or service not known>"
    #assert_match("Error: druby://non-existent-host:4440 - #<SocketError: getaddrinfo: nodename nor servname provided, or not known", output)
    assert (output =~ /SocketError/)
  end

  def test_show_with_one_agent
    console = Galaxy::Console.start({ :host => 'localhost', :log_level => Logger::WARN })
    begin
      agent = Galaxy::Agent.start({ :host => 'localhost', :console => 'localhost', :log_level => Logger::WARN })
      begin
        output = `#{GALAXY} -c localhost show -i localhost 2>&1`.split("\n")
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
