require 'net/http'
require 'thread'
require 'json'

module TagMaster
  class Distributor
    include Logger
    
    def initialize settings
      @settings = settings
      @queue = Queue.new
      @uri = URI(@settings["endpoint"])
      @http = Net::HTTP.new( @uri.host, @uri.port )
      @http.read_timeout = @settings["post_timeout"]
      @request = Net::HTTP::Post.new(@uri.path, {'Content-Type' =>'application/json'})
    end
    
    def start
      @thread = Thread.new do
        loop do
          begin
            event = @queue.pop
            send( event )
          rescue StandardError => e
            err "[#{format_time Time.now}] Send queue error: #{e}"
          end
        end
      end
    end
    
    def stop
      @thread.join
    end
    
    def enqueue event
      @queue << event
    end
    
    private
    
    def send event
      @request.body = event.to_json
      response = @http.request(@request)
      if response.code == "200"
        return true
      else
        err "[#{format_time Time.now}] Could not distribute #{event} - Response code #{response.code}"
        return false
      end
    rescue StandardError => e
      err "[#{format_time Time.now}] Could not distribute #{event} - #{e}"
      false
    end
  end
end