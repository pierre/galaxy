require 'tempfile'
require 'fileutils'

require 'galaxy/filter'
require 'galaxy/temp'
require 'galaxy/transport'
require 'galaxy/version'
require 'galaxy/versioning'

module Helper

  def Helper.mk_tmpdir
    Galaxy::Temp.mk_auto_dir "testing"
  end

  class Mock

    def initialize listeners={}
      @listeners = listeners
    end

    def method_missing sym, *args
      f = @listeners[sym]
      if f
        f.call(*args)
      end
    end
  end

end

class MockConsole
  def initialize agents
    @agents = agents
  end

  def shutdown
  end

  def agents filters = { :set => :all }
    filter = Galaxy::Filter.new filters
    @agents.select(&filter)
  end
end

class MockAgent
  attr_reader :agent_id, :agent_group, :config_path, :stopped, :started, :restarted
  attr_reader :gonsole_url, :env, :version, :type, :url, :agent_status, :proxy, :build, :core_type, :machine, :ip

  def initialize agent_id, agent_group, url, env = nil, version = nil, type = nil, gonsole_url=nil
    @agent_id = agent_id
    @agent_group = agent_group
    @env = env
    @version = version
    @type = type
    @gonsole_url = gonsole_url
    @stopped = @started = @restarted = false

    @url = url
    Galaxy::Transport.publish @url, self

    @config_path = nil
    @config_path = "/#{env}/#{version}/#{type}" unless env.nil? || version.nil? || type.nil?
    @agent_status = 'online'
    @status = 'online'
    @proxy = Galaxy::Transport.locate(@url)
    @build = "1.2.3"
    @core_type = 'test'

    @ip = nil
    @drb_url = nil
    @os = nil
    @machine = nil
  end

  def shutdown
    Galaxy::Transport.unpublish @url
  end

  def status
    OpenStruct.new(
          :agent_id => @agent_id,
          :agent_group => @agent_group,
          :url => @drb_url,
          :os => @os,
          :machine => @machine,
          :core_type => @core_type,
          :config_path => @config_path,
          :build => @build,
          :status => @status,
          :agent_status => 'online',
          :galaxy_version => Galaxy::Version
    )
  end

  def stop!
    @stopped = true
    status
  end

  def start!
    @started = true
    status
  end

  def restart!
    @restarted = true
    status
  end

  def become! path, versioning_policy = Galaxy::Versioning::StrictVersioningPolicy
    md = %r!^/([^/]+)/([^/]+)/(.*)$!.match path
    new_env, new_version, new_type = md[1], md[2], md[3]
    # XXX We don't test the versioning code - but it should go away soon
    #raise if @version == new_version
    @env = new_env
    @version = new_version
    @type = new_type
    @config_path = "/#{@env}/#{@version}/#{@type}"
    status
  end

  def update_config! new_version, versioning_policy = Galaxy::Versioning::StrictVersioningPolicy
    # XXX We don't test the versioning code - but it should go away soon
    #raise if @version == new_version
    @version = new_version
    @config_path = "/#{@env}/#{@version}/#{@type}"
    status
  end

  def check_credentials!(command, credentials)
      true
  end

  def inspect
      Galaxy::Client::SoftwareDeploymentReport.new.record_result(self)
  end
end
