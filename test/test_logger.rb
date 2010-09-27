$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__))

require 'test/unit'
require 'galaxy/events'
require 'galaxy/host'
require 'galaxy/log'

class TestLogger < Test::Unit::TestCase
    def setup
    end

    def teardown
        #puts `cat /tmp/galaxy_unit_test.log*`
        FileUtils.rm Dir.glob('/tmp/galaxy_unit_test.log*')
    end

    def test_initialize_dummy_event_sender
        glogger = Galaxy::Log::Glogger.new "/tmp/galaxy_unit_test.log"
        assert_kind_of Galaxy::DummyEventSender, glogger.event_dispatcher
        assert_kind_of Logger, glogger.log
    end

    def test_initialize_collector
        glogger = Galaxy::Log::Glogger.new "/tmp/galaxy_unit_test.log", "http://collector.com"
        assert_kind_of Galaxy::GalaxyLogEventSender, glogger.event_dispatcher
        assert_kind_of Logger, glogger.log
    end

    def test_syslog
        # Real-life example that was breaking 2.6.pre2
        logger = Galaxy::HostUtils.logger
        assert logger.debug("http://prod1.company.com:8080/1?v=GalaxyLog,81267034768000%2C4168954152%2C29654%2Csdebug%2Cs%2CsRegistered%2520Event%2520listener%2520type%2520Galaxy%253A%253AGalaxyEventSender%2520at%2520http%253A%252F%252Fz1205a9.company.com%253A8080%252C%2520sender%2520url%25200.1.9.4%2C&rt=b")
        assert logger.info("http://prod1.company.com:8080/1?v=GalaxyLog,81267034768000%2C4168954152%2C29654%2Csdebug%2Cs%2CsRegistered%2520Event%2520listener%2520type%2520Galaxy%253A%253AGalaxyEventSender%2520at%2520http%253A%252F%252Fz1205a9.company.com%253A8080%252C%2520sender%2520url%25200.1.9.4%2C&rt=b")
        assert logger.warn("http://prod1.company.com:8080/1?v=GalaxyLog,81267034768000%2C4168954152%2C29654%2Csdebug%2Cs%2CsRegistered%2520Event%2520listener%2520type%2520Galaxy%253A%253AGalaxyEventSender%2520at%2520http%253A%252F%252Fz1205a9.company.com%253A8080%252C%2520sender%2520url%25200.1.9.4%2C&rt=b")
        assert logger.error("http://prod1.company.com:8080/1?v=GalaxyLog,81267034768000%2C4168954152%2C29654%2Csdebug%2Cs%2CsRegistered%2520Event%2520listener%2520type%2520Galaxy%253A%253AGalaxyEventSender%2520at%2520http%253A%252F%252Fz1205a9.company.com%253A8080%252C%2520sender%2520url%25200.1.9.4%2C&rt=b")
    end

    def test_syslog_raw
        logger = Galaxy::HostUtils.logger
        assert logger << "foo bar baz"
    end

    def test_respect_loglevel_with_event_dispatcher
        glogger = Galaxy::Log::Glogger.new "/tmp/galaxy_unit_test.log", "non-existent-host", "http://gonsole.test.company.com:1242", "10.15.12.14"
        assert_kind_of Galaxy::GalaxyLogEventSender, glogger.event_dispatcher
        assert_kind_of Logger, glogger.log

        # Make sure we don't try to send events at the wrong level

        glogger.log.level = Logger::INFO
        assert glogger.debug("debug hello from unit test")

        glogger.log.level = Logger::DEBUG
        assert_raise URI::BadURIError do
            glogger.debug("debug hello from unit test")
        end
    end

    def test_syslog_level
        logger = Galaxy::HostUtils.logger

        assert_equal Logger::INFO, logger.level

        logger.level = Logger::DEBUG
        assert_equal Logger::DEBUG, logger.level
    end
end
