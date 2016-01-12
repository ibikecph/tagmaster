require 'digest/sha1'


module TagMaster  
  class Event

    attr_reader :type, :id, :status, :control, :user_data, :data, :metadata
    attr_reader :timestamp, :lag, :line, :type, :subtype, :formatbits

    def initialize h
      @data = h[:data]
      @metadata = h[:metadata]
      @timestamp = h[:timestamp]
      @line = h[:line]
      
      lag = h[:now] - @timestamp
      @lag = lag.round(3)
      parse
    end

    def parse
      raise TagError.new(@data,@formatbits) if @data.size < 2
      @formatbits = @data[1] & 0x3F
      if @formatbits == 0b111101
        parse_openlen
      else
        parse_fixedlen
      end
    end

    def parse_openlen
      @type = "OpenLen"
      len = @data[0]
      got = @data.size - 2
      if got == len+4
        check_csc @data
      end
      @id = Tagp.assemble_integer @data[2..-1]
    end

    def check_crc
    end

    def parse_fixedlen
      if data.size<=12
        parse_marktag
      else
        parse_scripttag
      end

      if @formatbits >= 0 && @formatbits <= 0b111100
        parse_mark28
      elsif @formatbits == 0b111111
        parse_open32
      elsif @formatbits == 0b111110
        parse_open48
      else
        # should never happen, since we've covered all values 0-255
        raise TagError.new @data, @formatbits
      end
    end

    def parse_marktag
      @subtype = "MarkTag"
      if @data.size>=10
        @status = ((@data[8] << 6) | (@data[9] >> 2)) & 0xFE
      end
    end

    def parse_scripttag
      @subtype = "ScriptTag"
      @id = ((@data[1] & 0x3F) << 22) | (@data[2] << 14) | (@data[3] << 6) | ((@data[4] & 0xFC) >> 2)
      @control = ((@data[8] << 6) | (@data[9] >> 2)) & 0xFE
      @user_data = @data[10..29]
      @user_data[user_data.size] = user_data.last & 0xC0     # remove CRC checksum
    end

    def parse_mark28
      raise TagError.new @data, @formatbits unless @data.size>=5
      @type = "Mark28"
      @id = ((@data[1] & 0x3f) << 22) | (@data[2] << 14) | (@data[3] << 6) | ((@data[4] & 0xfc) >> 2)    
    end

    def parse_open32
      raise TagError.new @data, @formatbits unless @data.size>=5      
      @type = "Open32"
      @id = (@data[0] << 24) | ((@data[1] & 0xC0) << 16) | (@data[2] << 14) | (@data[3] << 6) | ((@data[4] & 0xFC) >> 2)
    end

    def parse_open48
      raise TagError.new @data, @formatbits unless @data.size>=7    
      @type = "Open48"
      @id = (@data[0] << 40) | ((@data[1] & 0xC0) << 32) | (@data[2] << 30) | (@data[3] << 22) | (@data[4] << 14) | (@data[5] << 6) | ((@data[6] & 0xFC) >> 2)
    end

    def id_hex
      @id.to_i.to_s(16)
    end
    
    def key
      "#{@type}:#{id_hex}"
    end
    
    def encrypted_id salt
      Digest::SHA1.hexdigest "#{key}:#{salt}"
    end
    
  end

  class EventTag < Event
    def initialize h
      super
    end
  end

  class EventGone < Event
    attr_reader :count, :timestamp
    def initialize h
      super
      @count = h[:count]
      @timestamp = h[:timestamp]
    end
  end
end