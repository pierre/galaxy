require 'rubygems'
require 'etc'
require 'resolv'

class CommandLineError < Exception;
end

def prompt_and_wait_for_user_confirmation prompt
    confirmed = false
    loop do
        $stderr.print prompt
        $stderr.flush
        case $stdin.gets.chomp.downcase
            when "y"
                confirmed = true
                break
            when "n"
                break
            else
                $stderr.puts "Please enter 'y' or 'n'"
        end
    end
    confirmed
end

# Expand the supplied console_url (which may just consist of hostname) to a full URL, assuming DRb as the default transport
def normalize_console_url console_url
    console_url = "druby://#{console_url}" unless console_url.match(/^\w+:\/\//)
    console_url ="#{console_url}:4440" unless console_url.match(/:\d+$/)
    console_url
end
