require 'json'

module TagMaster
  module Logger
    
    def err hash
      $stderr.puts hash.to_json
      $stderr.flush
    end

    def log hash
      $stdout.puts hash.to_json
      $stdout.flush
    end

    def format_time t
      t.strftime('%Y-%m-%d %H:%M:%S.%L %z')
    end
  end
end