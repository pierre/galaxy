require 'fileutils'
require 'thread'
require 'tmpdir'

module Galaxy
    module Temp
        Mutex = Mutex.new

        def Temp.auto_delete path
            Kernel.at_exit do
                begin
                    FileUtils.rm_r(path) if File.exist? path
                rescue => e
                    puts "Failed to delete #{path}: #{e}"
                end
            end
            path
        end

        def Temp.mk_auto_file component="galaxy"
            auto_delete mk_file(component)
        end

        def Temp.mk_auto_dir component="galaxy"
            auto_delete mk_dir(component)
        end

        def Temp.mk_file component="galaxy"
            return * FileUtils.touch(next_name(component))
        end

        def Temp.mk_dir component="galaxy"
            return * FileUtils.mkdir(next_name(component))
        end

        private

        def Temp.next_name component
            Mutex.synchronize do
                @@id ||= 0
                name = "";
                loop do
                    @@id += 1
                    name = File.join Dir::tmpdir, "#{component}.#{Process.pid}.#{@@id}"
                    return name unless File.exists? name
                end
            end
        end
    end
end
