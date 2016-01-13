require 'socket'
require 'date'
require_relative 'tagp'
require_relative 'logger'
require_relative 'distributor'

module TagMaster
  class Receiver
    include Logger
    
    def initialize settings
      @settings = settings

      raise "Port settings is missing" unless @settings["port"]
      #raise "Locations settings is missing" unless @settings["locations"]
      #raise "Locations settings is empty" unless @settings["locations"].is_a?(Hash) && @settings["locations"].size>0

      @port = settings["port"]
      @whitelist = settings["whitelist"]
      @locations = settings["locations"]
    end

    def run
      starting
      server = TCPServer.new @port  # server on specific port
      loop do
        Thread.start(server.accept) do |client|    # wait for a client to connect
          begin
            handle_client client
          rescue StandardError => e
            err at:Time.now, msg:'exception',error:e.to_s,backtrace:e.backtrace
          end
        end
      end
    ensure
      exiting
    end
    
    def handle_client client
      sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
      connection = {ip:remote_ip, port:remote_port, hostname:remote_hostname, time:Time.now}
      if accept_connection? connection
        open_connection connection
        listen_to_client client, connection
        client.close
        close_connection connection
      else
        reject_connection connection
        client.close
      end
    end
    
    def listen_to_client client, connection
      while line = client.gets
        line.strip!
        begin
          now = Time.now
          process now, connection, line
        rescue StandardError => e
          err info(now,connection).merge( msg:'exception', error:e.to_s, backtrace:e.backtrace, raw:line )
        end
      end
    end
    
    def process now, connection, line
      e = TagMaster::Tagp.parse line, now
      if e
        unless accept_event? e
          return discard now, connection, e
        end        
        case e
        when EventTag
          return event now, connection, e
        when EventGone
          return gone now, connection, e
        end
      end
      not_understood now, connection
    end

    def starting
      log at: Time.now, msg: 'starting', port:@port
    end

    def exiting
      log at: Time.now, msg: 'exiting'
    end
  
    def accept_connection? connection
      if @locations
        @locations.include? connection[:ip]
      else
        true
      end
    end

    def info now, connection
      {
        at:now,
        ip:connection[:ip],
        port:connection[:port]      }
    end
    
    def open_connection connection
      log info(connection[:time],connection).merge( msg: 'connect',hostname: connection[:hostname] )
    end

    def reject_connection connection
      log info(connection[:time],connection).merge( msg: 'reject',hostname: connection[:hostname] )
    end

    def close_connection connection
      log info(connection[:time],connection).merge( msg: 'close',hostname: connection[:hostname] )
    end

    def event_info e
      {
        id: e.id,
        type: e.type,
        sub: e.subtype,
        time: e.timestamp,
        lag: e.lag,
        raw: e.line
      }
    end

    def accept_event? event
      return true if @whitelist == nil
      @whitelist.include?(event.type) && @whitelist[event.type].include?(event.id_hex)
    end

    def event now, connection, e
      log info(now,connection).merge(msg:'event').merge(event_info(e))
    end

    def gone now, connection, e
      log info(now,connection).merge(msg:'gone').merge(event_info(e))
    end

    def discard now, connection, e
      log info(now,connection).merge(msg:'discard').merge(event_info(e))
    end

    def not_understood now, connection
    end

  end

  class Server < Receiver
    def initialize settings
      super settings
      raise "Settings is empty" unless @settings
      raise "Endpoint settings is missing" unless @settings["endpoint"]
      raise "Retry delay settings is missing" unless @settings["retry_delay"]
      raise "Post timeout settings is missing" unless @settings["post_timeout"]

      @distributor = Distributor.new(@settings)
      @distributor.start
    end

    def accept_event? event
      return true if @whitelist == nil
      @whitelist.include?(event.type) && @whitelist[event.type].include?(event.id_hex)
    end

    def event now, connection, e
      location = @settings["locations"][connection[:ip]]
      return unless location && e.id && e.timestamp

      super now, connection, e

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