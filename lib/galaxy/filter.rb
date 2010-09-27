module Galaxy
    module Filter
        def self.new args
            filters = []

            case args[:set]
                when :all, "all"
                    filters << lambda { true }
                when :empty, "empty"
                    filters << lambda { |a| a.config_path.nil? }
                when :taken, "taken"
                    filters << lambda { |a| a.config_path }
            end

            if args[:env] || args[:version] || args[:type]
                env = args[:env] || "[^/]+"
                version = args[:version] || "[^/]+"
                type = args[:type] || ".+"

                filters << lambda { |a| a.config_path =~ %r!^/#{env}/#{version}/#{type}$! }
            end

            if args[:host]
                filters << lambda { |a| a.host == args[:host] }
            end

            if args[:ip]
                filters << lambda { |a| a.ip == args[:ip] }
            end

            if args[:machine]
                filters << lambda { |a| a.machine == args[:machine] }
            end

            if args[:state]
                filters << lambda { |a| a.status == args[:state] }
            end

            if args[:agent_state]
                p args[:agent_state]
                filters << lambda { |a| p a.agent_status; a.agent_status == args[:agent_state] }
            end

            lambda do |a|
                filters.inject(false) { |result, filter| result || filter.call(a) }
            end
        end
    end
end
