#! /usr/bin/ruby

require 'yaml'
require 'fileutils'
require 'erb'

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


@rc_agent_port = ResourceController.new 5400, 100
@rc_http_port = ResourceController.new 18080, 100
@rc_https_port = ResourceController.new 18443, 100
@rc_jmx_port = ResourceController.new 22345, 100
@rc_tomcat_ports = ResourceController.new 18200, 100
@rc_global_ports = ResourceController.new 20000, 10
@rc_private_ports = ResourceController.new 21000, 1000


@base = @config['base']
@config_dir = File.join(@base, "config")
@deploy_dir = File.join(@base, "deploy")

create_dir @base
create_dir @config_dir
create_dir @deploy_dir

puts "Created #{@base} as galaxy base directory."

@slots = @config['slots'].split(',')
@hostname = @config['hostname']
@host_prefix = @hostname.split('.')[0]

if @slots.empty?
    raise("No slots given, bailing out!")
end

global_ports = []
(0..4).entries.each { |x| global_ports[x] = @rc_global_ports.get }

internal_matches_external = @config['external-ip'].nil? || (@config['internal-ip'] == @config['external-ip'])

@slots.each do |@slot|
    http_port = @rc_http_port.get
    https_port = @rc_https_port.get

    slot_info = {
        "internal_ip" => @config['internal-ip'],
        "external_ip" => internal_matches_external ? @config['internal-ip'] : @config['external-ip'],
        "private_port_jmx" => @rc_jmx_port.get,
        "private_port_0" => @rc_private_ports.get,
        "private_port_1" => @rc_private_ports.get,
        "private_port_2" => @rc_private_ports.get,
        "private_port_3" => @rc_private_ports.get,
        "private_port_4" => @rc_private_ports.get,
        "global_port_0" => global_ports[0],
        "global_port_1" => global_ports[1],
        "global_port_2" => global_ports[2],
        "global_port_3" => global_ports[3],
        "global_port_4" => global_ports[4],
        "private_port_tomcat" => @rc_tomcat_ports.get,
        "internal_http" => http_port,
        "internal_https" => https_port,
        "external_http" => internal_matches_external ? @rc_http_port.get : http_port,
        "external_https" => internal_matches_external ? @rc_https_port.get : https_port
    }

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

File.open(File.join(@config_dir, "galaxy.conf"), "w") { |file|
    file.write @config_template.result
}

start_file=File.join(@base, "start_galaxy.sh")
@mode="-s"
File.open(start_file, "w") { |file| file.puts @script_template.result }
File.chmod(0755, start_file)

@mode="-k"
stop_file=File.join(@base, "stop_galaxy.sh")
File.open(stop_file, "w") { |file| file.puts @script_template.result }
File.chmod(0755, stop_file)

