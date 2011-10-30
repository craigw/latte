module Latte
  class Response
    initialize_with :query, :logger

    def add_answer record
      rr = parse_rr_string record
      packet.answer << rr
    end

    def data
      packet.data
    end

    def to_s
      packet.to_s
    end

    def parse_rr_string string
      Net::DNS::RR.new string
    end
    private :parse_rr_string

    def packet
      query.packet
    end
    private :packet
  end
end

