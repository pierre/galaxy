require 'thread'

class CountingSemaphore

    def initialize(initvalue = 0)
        @counter = initvalue
        @waiting_list = []
    end

    def wait
        Thread.critical = true
        if (@counter -= 1) < 0
            @waiting_list.push(Thread.current)
            Thread.stop
        end
        self
    ensure
        Thread.critical = false
    end

    def signal
        Thread.critical = true
        begin
            if (@counter += 1) <= 0
                t = @waiting_list.shift
                t.wakeup if t
            end
        rescue ThreadError
            retry
        end
        self
    ensure
        Thread.critical = false
    end

    def exclusive
        wait
        yield
    ensure
        signal
    end

end

class ThreadGroup

    def join
        list.each { |t| t.join }
    end

    def << thread
        add thread
    end

    def kill
        list.each { |t| t.kill }
    end

end

# execute in parallel with up to thread_count threads at once
class Array
    def parallelize thread_count=100
        sem = CountingSemaphore.new thread_count
        results = []
        threads = ThreadGroup.new
        lock = Mutex.new
        each_with_index do |item, i|
            sem.wait
            threads << Thread.new do
                begin
                    yield item
                ensure
                    sem.signal
                end
            end
        end

        threads.join

        results
    end
end
