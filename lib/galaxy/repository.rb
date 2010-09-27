require 'open-uri'
require 'logger'

module Galaxy
    class Repository
        def initialize base, log=Logger.new(STDOUT)
            @base = base
        end

        def walk hierarchy, file_name
            result = []
            hierarchy.split(/\//).inject([]) do |history, part|
                history << part
                begin
                    path = "#{history.join("/")}/#{file_name}"
                    url = "#{@base}#{path}"
                    open(url) do |io|
                        data = io.read
                        if block_given?
                            yield path, data
                        end
                        result << data
                    end
                rescue
                end
                history
            end

            result
        end
    end
end
