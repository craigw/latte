module Latte
  class Response
    initialize_with :query

    class BigEndianRecord < BinData::Record
      endian :big
    end

    class ResponseHeader < BigEndianRecord
      uint16 :id
      bit1   :qr
      bit4   :opcode
      bit1   :aa
      bit1   :tc
      bit1   :rd
      bit1   :ra
      bit3   :z, :value => 0 # Reserved for future use
      bit4   :rcode
      uint16 :qdcount
      uint16 :ancount
      uint16 :nscount
      uint16 :arcount
    end

    class Question < BigEndianRecord
      stringz :qname
      uint16 :qtype
      uint16 :qclass
    end

    class Answer < BigEndianRecord
      stringz :qname
      uint16 :qtype
      uint16 :qclass
      uint32 :ttl
      uint16 :rdlength, :value => lambda { rdata.length }
      string :rdata
    end

    def header
      ResponseHeader.new.tap { |h|
        h.id = query.id
        h.qr = 1 # I'm a response
        h.opcode = 0 # I'm a standard query
        h.aa = 0 # I'm not authoritative
        h.tc = 0 # I wasn't truncated
        h.rd = 0 # Please don't recursively query
        h.ra = 0 # Recursion isn't welcome here
        h.rcode = 0 # There are no errors here
        h.qdcount = 1 # You gave me one query
        h.ancount = answers.size # The number of answer records I'm sending
        h.nscount = 0 # There are 0 NS records in the authority spart
        h.arcount = 0 # There are 0 additional records in the additional part
      }
    end

    def question
      Question.new.tap { |q|
        q.qname = query.qname
        q.qtype = query.qtype
        q.qclass = query.qclass
      }
    end

    def answers
      @answers ||= [ example_answer ]
    end

    def example_answer
      Answer.new.tap { |a|
        a.qname = query.qname
        a.qtype = query.qtype
        a.qclass = query.qclass
        a.ttl = 0 # No cache thanks
        a.rdata = %w(127 0 0 1).map { |o| BinData::Uint8.new(o.to_i).to_binary_s }.join('')
      }
    end

    def to_s
      [ header, question, *answers ].map { |part|
        part.to_binary_s
      }.join ''
    end
  end
end
