require 'socket'
require_relative 'logger'
require_relative 'distributor'

module TagMaster
  class Server
    include Logger
    
    def initialize port
      @port = port
    end

    def run
      starting
      server = TCPServer.new @port  # server on specific port
      loop do
        Thread.start(server.accept) do |client|    # wait for a client to connect
          sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
          connection = {ip:remote_ip, port:remote_port, hostname:remote_hostname, now:Time.now}
          if accept? connection
            connected connection
            while line = client.gets.strip
              begin
                now = Time.now
                process now, connection, line
              rescue StandardError => er
                error connection, now, er, line
              end
            end
            client.close
            closed connection
          else
            rejected connection
            client.close
          end
        end
      end
    ensure
      exiting
    end

    def process now, connection, line
      event = Tagp.parse line, now
      case event
      when EventTag
        event connection, event
      when EventGone
        gone connection, event
      else
        unknown now, connection, line
      end
    end

    def starting
      log "[#{format_time Time.now}] Starting"
    end

    def accept? connection
      true
    end

    def connected connection
      log "#{format_connection(connection)} --> Connected #{connection[:hostname]}"
    end

    def rejected connection
      log "#{format_connection(connection)} --> Rejected #{connection[:hostname]}"
    end

    def closed connection
      log "#{format_connection(connection)} --> Closed #{connection[:hostname]}"
    end

    def event connection, e
      log "#{format_event(connection, e)} --> EVNT #{format_time(e.timestamp)} #{e.key.ljust 33} #{{lag:e.lag}.inspect}"
    end

    def gone connection, e
      log "#{format_event(connection, e)} --> GONE #{format_time(e.timestamp)} #{e.key.ljust 33} #{{lag:e.lag}.inspect}"
    end

    def unknown connection, now, e, line
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


  class Backend < Server
    def initialize settings
      @settings = settings
      raise "Settings is empty" unless @settings
      raise "Port settings is missing" unless @settings["port"]
      raise "Locations settings is missing" unless @settings["locations"]
      raise "Locations settings is empty" unless @settings["locations"].is_a?(Hash) && @settings["locations"].size>0
      raise "Endpoint settings is missing" unless @settings["endpoint"]
      raise "Retry delay settings is missing" unless @settings["retry_delay"]
      raise "Post timeout settings is missing" unless @settings["post_timeout"]

      super @settings["port"]
      @distributor = Distributor.new(@settings)
      @distributor.start
    end
    
    def accept? connection
      @settings["locations"].include? connection[:ip]
    end

    def event connection, e
      super connection, e
      location = @settings["locations"][connection[:ip]]
      @distributor.enqueue [location,format_time(e.timestamp), e.type, e.id_hex ]
    end
  end
  
end