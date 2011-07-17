require 'test/unit'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/agent'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/galaxy/agent/starter'))

class TestRepository < Test::Unit::TestCase

    DEPLOYMENTS_PATH = File.join(File.dirname(__FILE__), "/deployments")

    def setup
        @starter = Galaxy::Agent::Starter.new(Logger.new(STDOUT, Logger::INFO))
    end

    def test_working
        deployment_path = File.join(DEPLOYMENTS_PATH, "deployment-working")

        status = @starter.start!(deployment_path)
        assert_equal(Galaxy::Agent::Starter::RUNNING, status)

        status = @starter.stop!(deployment_path)
        assert_equal(Galaxy::Agent::Starter::STOPPED, status)

        status = @starter.restart!(deployment_path)
        assert_equal(Galaxy::Agent::Starter::RUNNING, status)

        # The "working" launcher always return 0
        status = @starter.status(deployment_path)
        assert_equal(Galaxy::Agent::Starter::STOPPED, status)
    end

    def test_broken
        deployment_path = File.join(DEPLOYMENTS_PATH, "deployment-broken")

        status = @starter.start!(deployment_path)
        assert_equal(Galaxy::Agent::Starter::STOPPED, status)

        status = @starter.stop!(deployment_path)
        assert_equal(Galaxy::Agent::Starter::RUNNING, status)

        status = @starter.restart!(deployment_path)
        assert_equal(Galaxy::Agent::Starter::STOPPED, status)

        # The "working" launcher always return 1
        status = @starter.status(deployment_path)
        assert_equal(Galaxy::Agent::Starter::RUNNING, status)
    end
end
