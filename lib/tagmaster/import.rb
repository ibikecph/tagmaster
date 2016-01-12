
module TagMaster  
  class Import
    
    attr_reader :result
    
    def initialize settings
      @settings = settings
      @filter = Filter.new @settings["whitelist"]
      @now = Time.now
      @result = [] 
    end
    
    def self.parse_line line
      # [2014-06-13 13:42:53.729] 95.209.153.196:59429   EVNTTAG 20140613133429755%00%09%B5:%FC%00%00%00%00%00%00%00     --> 2014-06-13 13:34:29.755 Mark28:40718015    {:lag=>503.974}
      if line =~ /^(\[.+\])\s+(\d+\.\d+\.\d+\.\d+):(\d+)\s+(EVNT.+)(?=-->)/
        time, ip, port, tagp = $1, $2, $3.to_i, $4.strip
        meta = line.match(/{.+}/)
        meta = meta.to_s if meta
        return ip, port, tagp
      end
    end
    
    def parse_tagp ip, port, tagp
      event = TagMaster::Tagp.parse tagp, @now
      if event
        process ip, port, event if event
      end
    rescue TagMaster::TagError => e
      fail tagp
    end
    
    def process ip, port, event
      return unless @filter.accept?(event)
      
      location = convert_location ip
      return unless location
      
      id = convert_id event
      return unless id
      
      # this will cause a slowdown for big files..
      row = { timestamp:event.timestamp, location:location, id:id }
      @result << row unless @result.include? row      
    end

    def format_time time
      time.strftime('%Y-%m-%d %H:%M:%S.%L %z')
    end
      
    def convert_location ip
      @settings["locations"][ip]
    end
      
    def convert_id event
      if @settings["encryption_key"]
        event.encrypted_id( @settings["encryption_key"] )
      else
        event.key
      end
    end

    def run path, &block
      lines = 0
      start = Time.now
      sec = nil
      total = `wc -l #{path}`.to_i rescue 1   # assumes we're on a system that has the wc command
      File.new(path).each_line do |line|
        ip, port, tagp = Import.parse_line line.scrub    # use scrub to fix invalid UTF byte sequences
        if tagp
          parse_tagp ip, port, tagp
        end
        lines += 1
        if block
          now = Time.now
          s = now.sec
          if (s!=sec) || (lines==total)
            sec = s
            percent = 100*lines.to_f/total
            used = now-start
            eta = percent>0 ? ((100-percent)*used/percent) : 0
            per_sec = used > 0 ? lines / used : 0
            block.call( percent.to_i, lines, total, used.to_i, eta.to_i, per_sec.to_i )
          end
        end
      end
      total
    end
    
    def sort
      @result.sort_by! { |h| h[:timestamp] }
    end
    
    def output
      @result.each do |row|
        puts [row[:timestamp].strftime('%Y-%m-%d %H:%M:%S.%L %z'),row[:location],row[:id]].join(',')
      end
    end
    
  end
end
