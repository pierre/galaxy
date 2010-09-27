###############################################################################
# daemonize.rb is a slightly modified version of daemonize.rb was             #
# from the Daemonize Library written by Travis Whitton                        #
# for details see http://grub.ath.cx/daemonize/                               #
###############################################################################

require 'galaxy/host'
require 'fileutils'

module Galaxy
    module Daemonize
        VERSION = "0.1.2"

        # Try to fork if at all possible retrying every 5 sec if the
        # maximum process limit for the system has been reached
        def safefork
            tryagain = true

            while tryagain
                tryagain = false
                begin
                    if pid = fork
                        return pid
                    end
                rescue Errno::EWOULDBLOCK
                    sleep 5
                    tryagain = true
                end
            end
        end

        # This method causes the current running process to become a daemon
        # If closefd is true, all existing file descriptors are closed
        def daemonize(log = nil, oldmode=0, closefd=false)
            srand # Split rand streams between spawning and daemonized process
            safefork and exit # Fork and exit from the parent

            # Detach from the controlling terminal
            unless sess_id = Process.setsid
                raise 'Cannot detach from controlled terminal'
            end

            # Prevent the possibility of acquiring a controlling terminal
            if oldmode.zero?
                trap 'SIGHUP', 'IGNORE'
                exit if pid = safefork
            end

            Dir.chdir "/" # Release old working directory
            File.umask 0000 # Insure sensible umask

            if closefd
                # Make sure all file descriptors are closed
                ObjectSpace.each_object(IO) do |io|
                    unless [STDIN, STDOUT, STDERR].include?(io)
                        io.close rescue nil
                    end
                end
            end

            log ||= "/dev/null"

            STDIN.reopen "/dev/null" # Free file descriptors and
            STDOUT.reopen log, "a" # point them somewhere sensible
            STDERR.reopen STDOUT # STDOUT/STDERR should go to a logfile
            return oldmode ? sess_id : 0 # Return value is mostly irrelevant
        end
    end

    class Daemon
        include Galaxy::Daemonize

        def self.pid_for pid_file
            begin
                File.open(pid_file) do |f|
                    f.gets
                end.to_i
            rescue Errno::ENOENT
                return nil
            end
        end

        def self.kill_daemon pid_file
            pid = pid_for(pid_file)
            if pid.nil?
                raise "Cannot determine process id: Pid file #{pid_file} not found"
            end
            begin
                Process.kill("TERM", pid)
            rescue Errno::ESRCH
                raise "Cannot kill process id #{pid}: Not running"
            rescue Errno::EPERM
                raise "Cannot kill process id #{pid}: Permission denied"
            end
        end

        def self.daemon_running? pid_file
            pid = pid_for(pid_file)
            if pid.nil?
                return false
            end
            begin
                Process.kill(0, pid)
            rescue Errno::ESRCH
                return false
            rescue Errno::EPERM
                return true
            end
            return true
        end

        def initialize & block
            @block = block
        end

        def go pid_file, log
            daemonize(log)

            File.open(pid_file, "w", 0644) do |f|
                f.write Process.pid
            end
            trap "TERM" do
                FileUtils.rm_f pid_file
                exit 0
            end
            trap "KILL" do
                FileUtils.rm_f pid_file
                exit 0
            end
            @block.call
        end

        def self.start name, pid_file, user = nil, log = nil, & block
            Galaxy::HostUtils::switch_user(user) unless user.nil?
            if daemon_running?(pid_file)
                pid = pid_for(pid_file)
                abort("Error: #{name} is already running as pid #{pid}")
            end
            Daemon.new(& block).go(pid_file, log)
        end
    end
end
