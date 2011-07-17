require 'tempfile'
require 'syslog'
require 'logger'

module Galaxy::Agent
    module HostUtils
        def HostUtils.logger ident="galaxy"
            @logger ||= begin
                log = Syslog.open ident, Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_LOCAL7
                class << log
                    attr_reader :level
                    # The interface is busted between Logger and Syslog. The later expects a format string. The former a string.
                    # This was breaking logging in the event code in production (we log the url, which contains escaped characters).
                    # Poor man's solution: assume the message is not a format string if we pass only one argument.
                    #
                    alias_method :unsafe_debug, :debug

                    def debug * args
                        args.length == 1 ? unsafe_debug(safe_format(args[0])) : unsafe_debug(* args)
                    end

                    alias_method :unsafe_info, :info

                    def info * args
                        args.length == 1 ? unsafe_info(safe_format(args[0])) : unsafe_info(* args)
                    end

                    def warn * args
                        args.length == 1 ? warning(safe_format(args[0])) : warning(* args)
                    end

                    def error * args
                        args.length == 1 ? err(safe_format(args[0])) : err(* args)
                    end

                    # set log levels from standard Logger levels
                    def level=(val)
                        @level = val
                        case val # Note that there are other log levels: LOG_EMERG, LOG_ALERT, LOG_CRIT, LOG_NOTICE
                            when Logger::ERROR
                                Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_ERR)
                            when Logger::WARN
                                Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_WARNING)
                            when Logger::DEBUG
                                Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
                            when Logger::INFO
                                Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_INFO)
                        end
                    end

                    def safe_format(arg)
                        return arg.gsub("%", "%%")
                    end

                    # The logger implementation dump msg directly, without appending any loglevel. We need one though for Syslog.
                    # By default, logger(1) uses ``user.notice''. Do the same here.
                    def <<(msg)
                        notice(msg)
                    end
                end
                log.level = Logger::INFO
                log
            end
        end

        def HostUtils.tar
            @tar ||= begin
                unless `which gtar` =~ /^no gtar/ || `which gtar`.length == 0
                    "gtar"
                else
                    "tar"
                end
            end
        end

        # An alternative to Kernel.system that invokes a command and returns STDOUT/STDERR and the return code
        def HostUtils.system command
            output = IO.popen("#{command} 2>&1") { |io| io.readlines }
            return output, $?.exitstatus
        end
    end
end
