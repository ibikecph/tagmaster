require_relative 'server'

module TagMaster
  class Scanner < Receiver

    def initialize port, path
      super "port"=>port
      @path = path
      @scanned = {}
    end
    
    def event now, connection, e
      unless @scanned[e.key]
        @scanned[e.key] = 1
        log info(now,connection).merge(msg:'unique', num:@scanned.size).merge(event_info(e))
      else
        @scanned[e.key] += 1
      end
    end

    def dump
      str = ""
      unless File.exists? @path
        File.open(@path,'w') { |file| file.write str }
      else
        log "Cannot write list of ids, since file #{@path} aready exists."
        #@scanned.sort_by { |k,v| v }.reverse.each do |t|
        #  k = t[0]
        #  v = t[1]
        #  str << "#{k[0].ljust 12} #{k[1].to_s(16).ljust 30} #{v.to_s.ljust 10}\n"      
        #end
      end
      log str
    end
      
  end
end
