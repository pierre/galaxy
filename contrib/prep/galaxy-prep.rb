#! /usr/bin/ruby
#
# Writes a set of configuration files and scripts to create a local galaxy installation.
#

require 'yaml'
require 'fileutils'
require 'erb'

# Maximum number of agents that can be created
max_agent_count = 20

# Number of private ports associated with each slot
private_ports_per_slot = 5

# Total number of global ports associated
num_global_ports = 5


class ResourceController
    def initialize start, amount
        @start = start
        @stop = start + amount
    end

    def get
        if @start > @stop
            raise("Resource exhausted (#{@start}, #{@stop}")
        end
        ret = @start
        @start = @start + 1
        ret
    end
end

def create_dir folder
    if !File.exists? folder
        FileUtils.mkdir_p folder
    end

    if !File.exists?(folder) || !File.directory?(folder)
        raise("Could not create #{folder} or it is not a directory!")
    end
end

ARGV.length == 1 || raise("Usage: #{$0} <config file>")

#
# Load configuration, validate it
#

@config = YAML.load_file(ARGV[0])

@agent_template = nil
File.open(@config['agent-template']) { |file|
  @agent_template = ERB.new file.read
}

@config_template = nil
File.open(@config['config-template']) { |file|
  @config_template = ERB.new file.read
}

@script_template = nil
File.open("script.erb") { |file|
  @script_template = ERB.new file.read
}

@user = @config['user'] || ENV['USER']

if @user.nil?
  raise("Could not determine the galaxy user")
end

@slots = @config['slots'].split(',')

if @slots.empty?
    raise("No slots given, bailing out!")
end

if @slots.length > max_agent_count
  raise("More than #{max_agent_count} slots defined, check the resource allocation first!")
end

@base = @config['base']

if @base.nil?
  raise("No base directory given!")
end

@hostname = @config['hostname']

if @hostname.nil?
  raise("No hostname given!")
end

@internal_ip = @config['internal-ip']

if @internal_ip.nil?
  raise("No internal ip given!")
end

#
# derived configuration
#

@config_dir = File.join(@base, "config")
@deploy_dir = File.join(@base, "deploy")
@host_prefix = @hostname.split('.')[0]
@external_ip = @config['external-ip'] || @internal_ip

internal_matches_external = @internal_ip == @external_ip

#
# Resource management agents.
#
# rc_agent_port    - ports used by the galaxy agents.
# rc_http_port     - http ports associated with a slot.
# rc_https_port    - https ports associated with a slot.
# rc_jmx_port      - jmx ports associated with a slot.
# rc_tomcat_port   - tomcat port associated with a slot.
# rc_private_ports - slot specific ports (every slot gets a couple).
# rc_global_ports  - https ports associated with a slot.
#
# TODO:
# - get rid of the tomcat_port, which is specific to an use case. Allow extension of the script to cater to these needs.
# - add a global resource allocator to avoid double assignment of a port in different resource controllers.

@rc_agent_port = ResourceController.new 5400, max_agent_count
@rc_http_port = ResourceController.new 18080, max_agent_count
@rc_https_port = ResourceController.new 18443, max_agent_count
@rc_jmx_port = ResourceController.new 22345, max_agent_count
@rc_tomcat_port = ResourceController.new 18200, max_agent_count
@rc_private_ports = ResourceController.new 21000, max_agent_count*private_ports_per_slot
@rc_global_ports = ResourceController.new 20000, num_global_ports

#
# Create galaxy base folders
#
create_dir @base
create_dir @config_dir
create_dir @deploy_dir

puts "Created #{@base} as galaxy base directory."

# Allocate global ports

global_ports = []
(0...num_global_ports).entries.each { |x| global_ports[x] = @rc_global_ports.get }

# prep each agent slot

@slots.each do |@slot|
    http_port = @rc_http_port.get
    https_port = @rc_https_port.get

    slot_info = {
        "internal_ip" => @internal_ip,
        "external_ip" => internal_matches_external ? @internal_ip : @external_ip,
        "private_port_jmx" => @rc_jmx_port.get,
        "private_port_tomcat" => @rc_tomcat_port.get,
        "internal_http" => http_port,
        "internal_https" => https_port,
        "external_http" => internal_matches_external ? @rc_http_port.get : http_port,
        "external_https" => internal_matches_external ? @rc_https_port.get : https_port
    }

    (0...global_ports.length).each { |x| slot_info["global_port_#{x}"] = global_ports[x] }
    (0...private_ports_per_slot).each { |x| slot_info["private_port_#{x}"] = @rc_private_ports.get }

    File.open(File.join(@config_dir, "slotinfo-#{@slot}"), "w") { |file|
        file.write(YAML.dump(slot_info))
    }

    FileUtils.mkdir_p File.join(@deploy_dir, @slot)
    FileUtils.mkdir_p File.join(@config_dir, "data-#{@slot}")

    File.open(File.join(@config_dir, "agent-#{@slot}.conf"), "w") { |file|
        file.write @agent_template.result
    }
    puts "Agent #{@slot} complete"
end

# write main configuration

File.open(File.join(@config_dir, "galaxy.conf"), "w") { |file|
    file.write @config_template.result
}

# write start and stop scripts.

start_file=File.join(@base, "start_galaxy.sh")
@mode="-s"
File.open(start_file, "w") { |file| file.puts @script_template.result }
File.chmod(0755, start_file)

@mode="-k"
stop_file=File.join(@base, "stop_galaxy.sh")
File.open(stop_file, "w") { |file| file.puts @script_template.result }
File.chmod(0755, stop_file)

