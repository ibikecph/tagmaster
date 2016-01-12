require 'socket'
require 'date'
require_relative 'tagp'
require_relative 'logger'
require_relative 'distributor'

module TagMaster
  class Receiver
    include Logger
    
    def initialize port, whitelist=nil
      @port = port
      @whitelist = whitelist
    end

    def run
      starting
      server = TCPServer.new @port  # server on specific port
      loop do
        Thread.start(server.accept) do |client|    # wait for a client to connect
          sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
          connection = {ip:remote_ip, port:remote_port, hostname:remote_hostname, now:Time.now}
          if accept_connection? connection
            open_connection connection
            while line = client.gets.strip
              begin
                now = Time.now
                process now, connection, line
              rescue StandardError => er
                error connection, now, er, line
              end
            end
            client.close
            close_connection connection
          else
            reject_connection connection
            client.close
          end
        end
      end
    ensure
      exiting
    end

    def process now, connection, line
      event = TagMaster::Tagp.parse line, now
      if event
        unless accept_event? event
          return rejected connection, event
        end
        
        case event
        when EventTag
          return event connection, event
        when EventGone
          return gone connection, event
        end
      end
      not_understood connection
    end
  
    def accept_event? event
      return true if @whitelist == nil
      @whitelist.include?(event.type) && @whitelist[event.type].include?(event.id_hex)
    end
  
    def starting
      log "[#{format_time Time.now}] Starting"
    end

    def accept_connection? connection
      true
    end

    def open_connection connection
      log "#{format_connection(connection)} --> Connected #{connection[:hostname]}"
    end

    def reject_connection connection
      log "#{format_connection(connection)} --> Rejected #{connection[:hostname]}"
    end

    def close_connection connection
      log "#{format_connection(connection)} --> Closed #{connection[:hostname]}"
    end

    def event connection, e
      log "#{format_event(connection, e)} --> EVNT #{format_time(e.timestamp)} #{e.key.ljust 33} #{{lag:e.lag}.inspect}"
    end
    
    def gone connection, e
      log "#{format_event(connection, e)} --> GONE #{format_time(e.timestamp)} #{e.key.ljust 33} #{{lag:e.lag}.inspect}"
    end

    def rejected connection, e
      log "#{format_event(connection, e)} --> RCJT #{format_time(e.timestamp)} #{e.key.ljust 33} #{{lag:e.lag}.inspect}"
    end

    def not_understood connection
      #log "#{format_info now, remote_ip, remote_port, line} --> Not understood"
    end

    def error connection, now, e, line
      log "#{format_connection(connection)} --> Exception! #{e}"
      log e.backtrace
    end

    def exiting
      log "[#{format_time Time.now}] Exiting"
    end

  end


  class Server < Receiver
    def initialize settings
      @settings = settings
      raise "Settings is empty" unless @settings
      raise "Port settings is missing" unless @settings["port"]
      raise "Locations settings is missing" unless @settings["locations"]
      raise "Locations settings is empty" unless @settings["locations"].is_a?(Hash) && @settings["locations"].size>0
      raise "Endpoint settings is missing" unless @settings["endpoint"]
      raise "Retry delay settings is missing" unless @settings["retry_delay"]
      raise "Post timeout settings is missing" unless @settings["post_timeout"]

      super @settings["port"], @settings["whitelist"]
      @distributor = Distributor.new(@settings)
      @distributor.start
    end

    def accept_connection? connection
      @settings["locations"].include? connection[:ip]
    end

    def event connection, e
      super connection, e
      location = @settings["locations"][connection[:ip]]
      return unless location && e.id && e.timestamp
      
      if @settings["encryption_key"]
        id = e.encrypted_id( @settings["encryption_key"] )
      else
        id = e.key
      end
      msg = { location:location, timestamp: e.timestamp.strftime('%Y-%m-%d %H:%M:%S.%L %z'), id:id }
      @distributor.enqueue msg
    end

  end
  
end