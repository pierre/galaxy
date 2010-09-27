module Galaxy
    module Commands
        class SSHCommand < Command
            register_command "ssh"

            def execute agents
                agent = agents.first
                command = ENV['GALAXY_SSH_COMMAND'] || "ssh"
                Kernel.system "#{command} #{agent.host}" if agent
            end

            def self.help
                return <<-HELP
#{name}
        
        Connect via ssh to the first host matching the selection criteria
        
        The GALAXY_SSH_COMMAND environment variable can be set to specify options for ssh.
        
        For example, this instructs galaxy to login as user 'foo':
        
            export GALAXY_SSH_COMMAND="ssh -l foo"
                HELP
            end
        end
    end
end
