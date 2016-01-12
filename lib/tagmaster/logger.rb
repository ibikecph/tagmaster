module TagMaster
  module Logger
    def err str
      $stderr.puts str
      $stderr.flush
    end

    def log str
      $stdout.puts str
      $stdout.flush
    end

    def format_connection c
      format_info(c[:now], c[:ip], c[:port])
    end

    def format_event c, e
      format_info(c[:now], c[:ip], c[:port], e.line)
    end

    def format_info now, ip, port, line=""
      ip_port = "#{ip}:#{port}"
      "[#{format_time(now)}] #{ip_port.ljust 22} #{line}".ljust(115)
    end

    def format_time t
      t.strftime('%Y-%m-%d %H:%M:%S.%L %z')
    end
  end
end