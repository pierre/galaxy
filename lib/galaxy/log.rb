require 'galaxy/host'

module Galaxy
    module Log
        class Glogger
            attr_reader :log

            def initialize(logdev, shift_age = 0, shift_size = 1048576)
                case logdev
                    when "SYSLOG"
                        @log = Galaxy::HostUtils.logger "galaxy"
                    when "STDOUT"
                        @log = Logger.new(STDOUT, shift_age, shift_size)
                    when "STDERR"
                        @log = Logger.new(STDERR, shift_age, shift_size)
                    else
                        @log = Logger.new(logdev, shift_age, shift_size)
                end
            end

            def debug(progname = nil, & block)
                @log.debug progname, & block
            end

            def error(progname = nil, & block)
                @log.error progname, & block
            end

            def fatal(progname = nil, & block)
                @log.fatal progname, & block
            end

            def info(progname = nil, & block)
                @log.info progname, & block
            end

            def warn(progname = nil, & block)
                @log.warn progname, & block
            end

            # Pipeline other methods to Logger
            # We don't want to define << for instance: when we'll end up having a dedicated Thrift
            # schema for logs, we do want to know beforehand the expected formatting.
            def method_missing(m, * args, & block)
                @log.send m, * args, & block
            end

            private

            def format_message(progname, & block)
                if block_given?
                    message = yield
                else
                    message = progname
                end
                message
            end
        end

        class LoggerIO < IO
            require 'strscan'

            def initialize log, level = :info
                @log = log
                @level = level
                @buffer = ""
            end

            def write str
                @buffer << str

                scanner = StringScanner.new(@buffer)

                while scanner.scan(/([^\n]*)\n/)
                    line = scanner[1]
                    case @level
                        when :warn
                            @log.warn line
                        when :info
                            @log.info line
                        when :error
                            @log.error line
                    end
                end

                @buffer = scanner.rest
            end
        end
    end
end

if __FILE__ == $0
    def a
        b
    end

    def b
        raise "error"
    end

    require 'logger'

    log = Logger.new(STDERR)
    info = Galaxy::Log::LoggerIO.new log, :info
    warn = Galaxy::Log::LoggerIO.new log, :error
    $stdout = info
    $stderr = warn

    puts "hello world\nbye bye"

    a
end
