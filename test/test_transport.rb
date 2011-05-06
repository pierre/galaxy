require 'test/unit'
require 'galaxy/transport'
require 'galaxy/console'

class TestTransport < Test::Unit::TestCase
  def test_handler_for
    assert Galaxy::Transport.handler_for("druby://xxxx:444").kind_of?(Galaxy::DRbTransport)
    assert Galaxy::Transport.handler_for("local://xxxx:444").kind_of?(Galaxy::LocalTransport)
    assert Galaxy::Transport.handler_for("http://xxxx:444").kind_of?(Galaxy::HttpTransport)
  end

  def test_handler_not_found
    assert_raises RuntimeError do
      Galaxy::Transport.handler_for("invalid://xxxx:444")
    end
  end

  def test_drb_publish
    url = "druby://localhost:4444"
    console = Galaxy::Transport.publish url, "hello"

    obj = Galaxy::Transport.locate url

    assert_equal "hello", obj.to_s
    console.stop_service
  end

  def test_drb_pool_size
    assert_equal 0, DRb::DRbConn::POOL_SIZE
  end

  def test_http_publish
    console = Galaxy::Console.start({ :host => 'localhost', :log_level => Logger::WARN })
    url = "http://localhost:4441"

    assert_raises TypeError do
      Galaxy::Transport.publish url, nil
    end

    console_logger = Logger.new(STDOUT)
    console_logger.level = Logger::WARN
    Galaxy::Transport.publish url, console, console_logger

    announcer = Galaxy::Transport.locate url
    o = OpenStruct.new(:host => "localhost", :url => url, :status => "running")
    assert_equal Galaxy::ReceiveAnnouncement::ANNOUNCEMENT_RESPONSE_TEXT, announcer.announce(o)

    Galaxy::Transport.unpublish url
    console.shutdown
  end

  def foo(a)
    $foo_called = true
  end

#  def test_http_publish_with_callback
#    url = "http://localhost:4442"
#    Galaxy::Transport.publish url, lambda{|a| foo(a) }
#
#    ann = Galaxy::Transport.locate url
#    $foo_called = false
#    ann.announce("announcement")
#    assert $foo_called == true
#
#    Galaxy::Transport.unpublish url
#  end

end
