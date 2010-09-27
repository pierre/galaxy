$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/events'
require 'logger'

class TestEvent < Test::Unit::TestCase

    # Set your collector hostname here to run tests.
    # See http://github.com/ning/collector
    COLLECTOR_HOST = nil

    def test_collectors
        unless COLLECTOR_HOST.nil?
            send_log
            send_raw_event
            send_success_event
            send_error_event
            build_number_string
        else
            assert true
        end
    end

    def setup
        logger = Logger.new(STDOUT)
        logger.level = Logger::WARN

        @galaxy_sender = Galaxy::GalaxyEventSender.new(COLLECTOR_HOST, "http://gonsole.testing.company.net:1242", "127.0.0.1", logger)
        @log_sender = Galaxy::GalaxyLogEventSender.new(COLLECTOR_HOST, "http://gonsole.testing.company.net:1242", "127.0.0.1", logger)

        @event = OpenStruct.new(
                 :host => "prod1.company.com",
                 :ip => "192.168.12.42",
                 :url => "drb://goofabr.company.pouet",
                 :os => "Linux",
                 :machine => "foobar",
                 :core_type => "tester",
                 :config_path => "conf/bar/baz",
                 :build => "124212",
                 :status => "running",
                 :agent_status => "online",
                 :galaxy_version => "2.5.1",
                 :user => "John Doe",
                 :gonsole_url => "http://gonsole.qa.company.net:4442"
           )
    end

    # More tests in test_logger.rb
    def send_log
        assert @log_sender.dispatch_error_log("Hello world!", "program_test")
    end

    def send_raw_event
        assert @galaxy_sender.send_event(@event)
    end

    def send_success_event
        assert @galaxy_sender.dispatch_announce_success_event(@event)
    end

    def send_error_event
        assert @galaxy_sender.dispatch_perform_error_event(@event)
    end

    def build_number_string
        event = OpenStruct.new(
                 :agent_status => "online",
                 :os => "solaris",
                 :host => "prod1.company.com",
                 :galaxy_version => "2.6.0.5",
                 :core_type => "apache",
                 :machine => "localhost",
                 :status => "stopped",
                 :url => "drb://prod2.company.com:4441",
                 :config_path => "alpha/DEP-1/apache",
                 :build => "6.1.10",
                 :ip => "0.1.9.1"
           )
        assert @galaxy_sender.dispatch_announce_success_event(event)
    end
end
