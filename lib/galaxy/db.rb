require 'thread'

module Galaxy
    class DB
        def initialize path
            @lock = Mutex.new
            @path = path
            Dir.mkdir @path rescue nil
        end

        def delete_at key
            @lock.synchronize do
                FileUtils.rm_f file_for(key)
            end
        end

        def []= key, value
            @lock.synchronize do
                File.open file_for(key), "w" do |f|
                    f.write(value)
                end
            end
        end

        def [] key
            @lock.synchronize do
                result = nil
                begin
                    File.open file_for(key), "r" do |f|
                        result = f.read
                    end
                rescue Errno::ENOENT
                end

                return result
            end
        end

        def file_for key
            File.join(@path, key)
        end
    end
end
