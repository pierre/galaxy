$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/events'
require 'galaxy/host'
require 'galaxy/log'

class TestLoggerCollector < Test::Unit::TestCase

    # Set your collector hostname here to run tests.
    # See http://github.com/ning/collector
    COLLECTOR_HOST = nil

    def test_collectors
        unless COLLECTOR_HOST.nil?
            send_event_via_event_dispatcher
            send_encoded_event_via_event_dispatcher
        else
            assert true
        end
    end

    def send_event_via_event_dispatcher
        glogger = Galaxy::Log::Glogger.new "/tmp/galaxy_unit_test.log", COLLECTOR_HOST, "http://gonsole.test.company.com:1242", "10.15.12.14"
        assert_kind_of Galaxy::GalaxyLogEventSender, glogger.event_dispatcher
        assert_kind_of Logger, glogger.log

        assert glogger.event_dispatcher.dispatch_debug_log("debug hello from unit test")
        assert glogger.event_dispatcher.dispatch_info_log("info hello from unit test")
        assert glogger.event_dispatcher.dispatch_warn_log("warn hello from unit test")
        assert glogger.event_dispatcher.dispatch_error_log("error hello from unit test")
        assert glogger.event_dispatcher.dispatch_fatal_log("fatal hello from unit test")
    end

    def send_encoded_event_via_event_dispatcher
        glogger = Galaxy::Log::Glogger.new "/tmp/galaxy_unit_test.log", COLLECTOR_HOST, "http://gonsole.test.company.com:1242", "10.15.12.14"
        assert_kind_of Galaxy::GalaxyLogEventSender, glogger.event_dispatcher
        assert_kind_of Logger, glogger.log

        assert glogger.event_dispatcher.dispatch_error_log("i love spaces")
        assert glogger.event_dispatcher.dispatch_error_log("drb://slashespowaa.com")
        assert glogger.event_dispatcher.dispatch_error_log("Embedded Thrift: ,sMyThrift,412")
        assert glogger.event_dispatcher.dispatch_error_log("$rr0r haZ !@#\$%^&*()_+{}:<>?/.,';#][\/~-`")
    end
end
