
module TagMaster  
  class Import
    
    def initialize
      @now = Time.now
    end
    
    def self.parse_line line
      # [2014-06-13 13:42:53.729] 95.209.153.196:59429   EVNTTAG 20140613133429755%00%09%B5:%FC%00%00%00%00%00%00%00     --> 2014-06-13 13:34:29.755 Mark28:40718015    {:lag=>503.974}
      if line =~ /(\[.+\])\s+(\d+\.\d+\.\d+\.\d+):(\d+)\s+(EVNT\w{3} .+?)\s/
        time, ip, port, tagp = $1, $2, $3.to_i, $4
        meta = line.match(/{.+}/)
        meta = meta.to_s if meta
        return time, ip, port, tagp, meta
      end
    end
    
    def parse_tagp time, ip, port, tagp, meta, line
      event = Tagp.parse tagp, @now
      receive event, time, ip, port, tagp, meta, line if event
    rescue TagError => e
      fail tagp
    end
    
    def receive event, time, ip, port, tagp, meta, line
    end
    
    def fail line
    end
    
    def run path, &block
      lines = 0
      start = Time.now
      sec = nil
      total = `wc -l #{path}`.to_i rescue 1   # assumes we're on a system that has the wc command
      File.new(path).each_line do |line|
        time, ip, port, tagp, meta = Import.parse_line line.scrub    # use scrub to fix invalid UTF byte sequences
        if tagp
          parse_tagp time, ip, port, tagp, meta, line
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
    end
    
  end
end
