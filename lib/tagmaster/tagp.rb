require_relative 'event.rb'
require_relative 'error.rb'
require_relative 'logger.rb'

module TagMaster
  class Tagp
    
    def self.build_time year, month, day, hour, minute, second, millisecond
      utc_offset = Time.now.strftime("%:z")   # eg "+01:00"
      second_with_fraction = Rational( second*1000 + millisecond, 1000 ) # eg 5234/1000
      Time.new(year, month, day, hour, minute, second_with_fraction, utc_offset)
    end
    
    def self.parse line, now
      if line =~ /EVNTTAG (\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{3})(.+)(?=-->)?/
        year, month, day, hour, minute, second, millisecond =
          $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i
        time = build_time(year, month, day, hour, minute, second, millisecond)
        data = decode_data $8.strip
        EventTag.new now: now, data: data, metadata: $10, line: line, timestamp: time
      elsif line =~ /^EVNTGONE(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{3})(.*);(.*)$/
        year, month, day, hour, minute, second, millisecond =
          $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i
        time = build_time(year, month, day, hour, minute, second, millisecond)
        data = decode_data $8.strip
        EventGone.new now: now, data: data, count: $9, line: line, timestamp: time
      end
    rescue Exception => e
      puts e
    end
    
    def self.assemble_integer data
      sum = 0
      k = 0
      data.reverse.each do |v|
        sum += v << k
        k += 8
      end
      sum
    end

    def self.decode_int str
      str.gsub(/%(..)/) { |v| v.hex}.hex
    end

    def self.decode_data str
      data = []
      str.scan(/(%(..)|.)/) do |match|
        if match[1]
          data << match[1].hex
        else
          data << match[0][0].ord
        end
      end
      data
    end

  end
end
