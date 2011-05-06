require 'test/unit'
require 'galaxy/command'
require 'galaxy/transport'
require 'helper'

class TestCommands < Test::Unit::TestCase
  def setup
    @agents = [
      MockAgent.new("agent1", "testgroup", "local:agent1", "alpha", "1.0", "sysc"),
      MockAgent.new("agent2", "testgroup", "local:agent2", "alpha", "1.0", "idtc"),
      MockAgent.new("agent3", "testgroup", "local:agent3", "alpha", "1.0", "appc/aclu0"),
      MockAgent.new("agent4", "testgroup", "local:agent4"),
      MockAgent.new("agent5", "testgroup", "local:agent5", "alpha", "2.0", "sysc"),
      MockAgent.new("agent6", "testgroup", "local:agent6", "beta", "1.0", "sysc"),
      MockAgent.new("agent7", "testgroup", "local:agent7")
    ]

    @console = MockConsole.new(@agents)
  end

  def teardown
    @agents.each { |a| a.shutdown }
    @console.shutdown
  end

  def test_all_registered
    assert Galaxy::Commands["assign"]
    assert Galaxy::Commands["clear"]
    assert Galaxy::Commands["reap"]
    assert Galaxy::Commands["restart"]
    assert Galaxy::Commands["rollback"]
    assert Galaxy::Commands["show"]
    assert Galaxy::Commands["ssh"]
    assert Galaxy::Commands["start"]
    assert Galaxy::Commands["stop"]
    assert Galaxy::Commands["update"]
    assert Galaxy::Commands["update-config"]
  end

  def internal_test_all_for cmd
    command = Galaxy::Commands[cmd].new [], {:console => @console}
    agents = command.select_agents(:set => :all)
    command.execute agents

    @agents.select { |a| a.config_path }.each { |a| assert_equal true, yield(a) }
    @agents.select { |a| a.config_path.nil? }.each { |a| assert_equal false, yield(a) }
  end

  def internal_test_by_id cmd
    command = Galaxy::Commands[cmd].new [], {:console => @console}
    agents = command.select_agents(:agent_id => "agent1")
    command.execute agents

    @agents.select {|a| a.agent_id == "agent1" }.each { |a| assert_equal true, yield(a) }
    @agents.select {|a| a.agent_id != "agent1" }.each { |a| assert_equal false, yield(a) }
  end

  def internal_test_by_type cmd
    command = Galaxy::Commands[cmd].new [], {:console => @console}
    agents = command.select_agents(:type => "sysc")
    command.execute agents

    @agents.select {|a| a.type == "sysc" }.each { |a| assert_equal true, yield(a) }
    @agents.select {|a| a.type != "sysc" }.each { |a| assert_equal false, yield(a) }
  end

  def test_stop_all
    internal_test_all_for("stop") { |a| a.stopped }
  end

  def test_start_all
    internal_test_all_for("start") { |a| a.started }
  end

  def test_restart_all
    internal_test_all_for("restart") { |a| a.restarted }
  end

  def test_stop_by_host
    internal_test_by_id("stop") { |a| a.stopped }
  end

  def test_start_by_host
    internal_test_by_id("start") { |a| a.started }
  end

  def test_restart_by_host
    internal_test_by_id("restart") { |a| a.restarted }
  end

  def test_stop_by_type
    internal_test_by_type("stop") { |a| a.stopped }
  end

  def test_start_by_type
    internal_test_by_type("start") { |a| a.started }
  end

  def test_restart_by_type
    internal_test_by_type("restart") { |a| a.restarted }
  end

  def test_show_all
    command = Galaxy::Commands["show"].new [], {:console => @console}
    agents = command.select_agents(:set => :all)
    results = command.execute agents

    assert_equal format_agents, results
  end

  def test_show_by_env
    command = Galaxy::Commands["show"].new [], {:console => @console}
    agents = command.select_agents(:env => "alpha")
    results = command.execute agents

    assert_equal format_agents(@agents.select {|a| a.env == "alpha"}), results
  end

  def test_show_by_version
    command = Galaxy::Commands["show"].new [], {:console => @console, :version => "1.0"}
    agents = command.select_agents(:version => "1.0")
    results = command.execute agents

    assert_equal format_agents(@agents.select {|a| a.version == "1.0"}), results
  end

  def test_show_by_type
    command = Galaxy::Commands["show"].new [], {:console => @console}
    agents = command.select_agents(:type => :sysc)
    results = command.execute agents

    assert_equal format_agents(@agents.select {|a| a.type == "sysc"}), results
  end

  def test_show_by_type2
    command = Galaxy::Commands["show"].new [], {:console => @console}
    agents = command.select_agents(:type => "appc/aclu0")
    results = command.execute agents

    assert_equal format_agents(@agents.select {|a| a.type == "appc/aclu0"}), results
  end

  def test_show_by_env_version_type
    command = Galaxy::Commands["show"].new [], {:console => @console}
    agents = command.select_agents({:type => "sysc", :env => "alpha", :version => "1.0"})
    results = command.execute agents

    assert_equal format_agents(@agents.select {|a| a.type == "sysc" && a.env == "alpha" && a.version == "1.0"}), results
  end

  def test_assign_empty
    command = Galaxy::Commands["assign"].new ["beta", "3.0", "rslv"], {:console => @console, :set => :empty}
    agents = command.select_agents(:set => :all)
    agent = @agents.select { |a| a.config_path.nil? }.first
    command.execute agents
    assert_equal "beta", agent.env
    assert_equal "rslv", agent.type
    assert_equal "3.0", agent.version
  end

  def test_assign_by_host
    agent = @agents.select { |a| a.agent_id == "agent7" }.first

    command = Galaxy::Commands["assign"].new ["beta", "3.0", "rslv"], { :console => @console }
    agents = command.select_agents(:agent_id => agent.agent_id)
    command.execute agents

    assert_equal "beta", agent.env
    assert_equal "rslv", agent.type
    assert_equal "3.0", agent.version
  end

  def test_clear
    # TODO
  end

  def test_clear_by_host
    # TODO
  end

  def test_update_by_id
    agent = @agents.select { |a| !a.config_path.nil? }.first
    env = agent.env
    type = agent.type

    command = Galaxy::Commands["update"].new ["4.0"], { :console => @console }
    agents = command.select_agents(:agent_id => agent.agent_id)
    command.execute agents

    assert_equal env, agent.env
    assert_equal type, agent.type
    assert_equal "4.0", agent.version
  end

  def test_update_config_by_version
    agent = @agents.select { |a| !a.config_path.nil? }.first
    env = agent.env
    type = agent.type

    command = Galaxy::Commands["update-config"].new ["4.0"], { :console => @console }
    agents = command.select_agents(:version => "1.0")
    results = command.execute agents
    assert_equal env, agent.env
    assert_equal type, agent.type
    assert_equal "4.0", agent.version
  end

  private

  def format_agents(agents=@agents)
    res = agents.inject("") do |memo, a|
        memo.empty? ? a.inspect : memo.to_s + a.inspect
    end
    res
  end
end
