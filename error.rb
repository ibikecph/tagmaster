module Tagp
	class TagError < RuntimeError
		attr_reader :data, :formatbits
		def initialize data, formatbits
		  @data = data
		  @formatbits = formatbits
		end
	end
end