module Latte
  class Address
    def self.default
      @default ||= new
    end

    initialize_with :raw_string

    def protocol
      matches = string.scan /^(udp|tcp):\/\//
      return matches[0][0] unless matches[0].nil?
    end
    default_value_of :protocol, 'udp'

    def ip_address
      matches = string.scan /(\d+\.\d+\.\d+\.\d+)/
      return matches[0][0] unless matches[0].nil?
    end
    default_value_of :ip_address, '127.0.0.1'

    def port
      matches = string.scan /:(\d+)$/
      return matches[0][0].to_i unless matches[0].nil?
    end
    default_value_of :port, 53

    def string
      raw_string.to_s.strip
    end
    private :string

    def to_s
      "#{protocol}://#{ip_address}:#{port}"
    end
  end
end
