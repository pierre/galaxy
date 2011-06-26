require 'test/unit'
require 'galaxy/announcements'

class TestAnnouncements < Test::Unit::TestCase

  # example callback for action upon receiving an announcement
  def on_announcement(ann)
    assert "bar" == ann.foo     # these are not Test::Unit asserts, but $received won't be set if any are false
    assert ann.rand >= 0
    assert ann.rand < 10
    assert "eggs" == ann.item
    @@received = true
  end

  def test_server
#    url = "http://localhost:8000"   # 4442 for announcements in production, but can be anything for test
#    # server
#    Galaxy::HTTPAnnouncementReceiver.new(url, lambda{|a| on_announcement(a)})
#
#    # sender
#    announcer = HTTPAnnouncementSender.new(url)
#    @@received = false
#    announcer.announce(OpenStruct.new(:foo=>"bar", :rand => rand(10), :item => "eggs"))
#    assert_equal true, @@received
  end
end
