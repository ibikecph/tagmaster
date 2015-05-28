require './event'
require './error'
require './logger'

module Tagp
  class Tagp
    
    def self.parse line, now
      if line =~ /^EVNTTAG (\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{3})([^;]+)(;(.*))?/
        year, month, day, hour, minute, second, millisecond =
          $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i
        EventTag.new now: now, data: decode_data($8), metadata: $10, line: line,
          timestamp: Time.local(year, month, day, hour, minute, second, millisecond*1000)
      elsif line =~ /^EVNTGONE(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{3})(.*);(.*)/
        year, month, day, hour, minute, second, millisecond =
          $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i
        EventGone.new now: now, data: decode_data($8), count: $9, line: line,
          timestamp: Time.local(year, month, day, hour, minute, second, millisecond*1000)
      else
        #puts 'not recognized'
      end
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
