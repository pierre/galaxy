require 'test/unit'
require 'ostruct'
require 'galaxy/filter'

class TestFilter < Test::Unit::TestCase
  def setup
    @null = OpenStruct.new({ })

    @foo = OpenStruct.new({ 
      :agent_id => 'foo',
      :agent_group => 'group1',
      :machine => 'foomanchu',
      :config_path => '/alpha/1.0/bloo',
      :status => 'running',
    })

    @bar = OpenStruct.new({ 
      :agent_id => 'bar',
      :agent_group => 'group2',
      :machine => 'barmanchu',
      :config_path => '/beta/2.0/blar',
      :status => 'stopped',
    })

    @baz = OpenStruct.new({ 
      :agent_id => 'baz',
      :agent_group => 'group3',
      :machine => 'bazmanchu',
      :config_path => '/gamma/3.0/blaz',
      :status => 'dead',
    })

    @blee = OpenStruct.new({ 
      :agent_id => 'blee',
      :agent_group => 'group4',
      :machine => 'bleemanchu',
    })

    @agents = [@null, @foo, @bar, @baz, @blee]
  end
    
  def test_filter_default
    filter = Galaxy::Filter.new({ })
    
    assert_equal @agents.size, @agents.select(&filter).size
  end

  def test_filter_none
    filter = Galaxy::Filter.new({ :set => :none})

    assert_equal 0, @agents.select(&filter).size
  end

  def test_filter_by_known_host
    filter = Galaxy::Filter.new :agent_id => "foo"

    assert_equal [@foo], @agents.select(&filter)
  end

  def test_filter_by_unknown_host
    filter = Galaxy::Filter.new :agent_id => "unknown"
    
    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_known_machine
    filter = Galaxy::Filter.new :machine => "foomanchu"
    
    assert_equal [@foo], @agents.select(&filter)
  end
  
  def test_filter_by_unknown_machine
    filter = Galaxy::Filter.new :machine => "unknown"
    
    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_known_ip
    filter = Galaxy::Filter.new :agent_group => "group1"
    
    assert_equal [@foo], @agents.select(&filter)
  end
  
  def test_filter_by_unknown_ip
    filter = Galaxy::Filter.new :agent_group => "20.0.0.1"
    
    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_state_running
    filter = Galaxy::Filter.new :state => "running"
    
    assert_equal [@foo], @agents.select(&filter)
  end
  
  def test_filter_by_state_stopped
    filter = Galaxy::Filter.new :state => "stopped"
    
    assert_equal [@bar], @agents.select(&filter)
  end
  
  def test_filter_by_state_dead
    filter = Galaxy::Filter.new :state => "dead"
    
    assert_equal [@baz], @agents.select(&filter)
  end
  
  def test_filter_by_unknown_state
    filter = Galaxy::Filter.new :state => "unknown"
    
    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_known_env
    filter = Galaxy::Filter.new :env => "beta"
    
    assert_equal [@bar], @agents.select(&filter)
  end
  
  def test_filter_by_known_env
    filter = Galaxy::Filter.new :env => "unknown"
    
    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_known_version
    filter = Galaxy::Filter.new :version => "1.0"
    
    assert_equal [@foo], @agents.select(&filter)
  end
  
  def test_filter_by_unknown_version
    filter = Galaxy::Filter.new :version => "0.0"
    
    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_known_type
    filter = Galaxy::Filter.new :type => "bloo"

    assert_equal [@foo], @agents.select(&filter)
  end
  
  def test_filter_by_unknown_type
    filter = Galaxy::Filter.new :type => "unknown"

    assert_equal [ ], @agents.select(&filter)
  end
  
  def test_filter_by_assigned
    filter = Galaxy::Filter.new :set => :taken

    assert_equal [@foo, @bar, @baz], @agents.select(&filter)
  end
  
  def test_filter_by_unassigned
    filter = Galaxy::Filter.new :set => :empty

    assert_equal [@null, @blee], @agents.select(&filter)
  end
  
  def test_filter_all
    filter = Galaxy::Filter.new :set => :all

    assert_equal @agents, @agents.select(&filter)
  end


  #####################################################################################
  # The following are additions for GAL-151. Given the way the code is _currently_
  # written, we really only need to check against host and machine, but the others are
  # added for increased safety and future-proofing
  #
  def test_filter_by_unknown_host_like_known_host
    filter = Galaxy::Filter.new :agent_id => "fo"     #don't match with "foo"

    assert_equal [ ], @agents.select(&filter)
  end

  def test_filter_by_unknown_machine_like_known_machine
    filter = Galaxy::Filter.new :machine => "fooman"    # don't match with "foomanchu"

    assert_equal [ ], @agents.select(&filter)
  end

  def test_filter_by_unknown_ip_like_known_ip
    filter = Galaxy::Filter.new :agent_group => "group"        # don't match with "group1"

    assert_equal [ ], @agents.select(&filter)
  end

  def test_filter_by_unknown_env_like_known_env
    filter = Galaxy::Filter.new :env => "bet"          #don't match with "beta"

    assert_equal [ ], @agents.select(&filter)
  end

  def test_filter_by_unknown_version_like_known_version
    filter = Galaxy::Filter.new :version => "1."       #don't match with "1.0"

    assert_equal [ ], @agents.select(&filter)
  end

  def test_filter_by_unknown_type_like_known_type
    filter = Galaxy::Filter.new :type => "blo"          # don't match with "bloo"

    assert_equal [ ], @agents.select(&filter)
  end

end
