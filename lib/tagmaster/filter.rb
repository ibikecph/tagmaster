
module TagMaster  
  class Filter
    def initialize whitelist
      @whitelist = whitelist
    end
    
    def accept? event
      return true unless @whitelist
      @whitelist.include?(event.type) && @whitelist[event.type].include?(event.id_hex)    
    end
  end
end




