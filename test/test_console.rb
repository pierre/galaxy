$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/transport'
require 'galaxy/config'
require 'galaxy/console'
require 'thread'
require 'timeout'
require 'helper'

class TestConsole < Test::Unit::TestCase

  def setup
    @foo = OpenStruct.new({
      :host => 'foo',
      :ip => '10.0.0.1',
      :machine => 'foomanchu',
      :config_path => '/alpha/1.0/bloo',
      :status => 'running'
    })

    @bar = OpenStruct.new({
      :host => 'bar',
      :ip => '10.0.0.2',
      :machine => 'barmanchu',
      :config_path => '/beta/2.0/blar',
      :status => 'stopped'
    })

    @baz = OpenStruct.new({
      :host => 'baz',
      :ip => '10.0.0.3',
      :machine => 'bazmanchu',
      :config_path => '/gamma/3.0/blaz',
      :status => 'dead'
    })

    @blee = OpenStruct.new({
      :host => 'blee',
      :ip => '10.0.0.4',
      :machine => 'bleemanchu'
    })

    @console = Galaxy::Console.start({:host => "localhost", :url => "druby://localhost:4449"})
  end

  def teardown
    @console.shutdown
  end

  def test_updates_last_announced_on_announce
    assert_nil @console.db["foo"]

    @console.send("announce", @foo)
    first = @console.db["foo"].timestamp
    @console.send("announce", @foo)
    second = @console.db["foo"].timestamp

    assert second > first
  end

  def test_list_agents
    @console.send("announce", @foo)
    @console.send("announce", @bar)
    @console.send("announce", @baz)

    agents = @console.agents
    assert_equal 3, agents.length

    assert agents.include?(@foo)
    assert agents.include?(@bar)
    assert agents.include?(@baz)
  end
end
