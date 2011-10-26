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
        h.qdcount = 1 # I'm answering one query
        h.ancount = answers.size # The number of answer records I'm sending
        h.nscount = 0 # There are 0 NS records in the authority part
        h.arcount = 0 # How many additional records am I sending?
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
      @answers ||= [ ]
    end

    class RecordParser
      initialize_with :record_string
      private_attr_accessor :record
      public :record

      # QTYPE codes:
      # A 1 a host address
      # NS 2 an authoritative name server
      # MD 3 a mail destination (Obsolete - use MX)
      # MF 4 a mail forwarder (Obsolete - use MX)
      # CNAME 5 the canonical name for an alias
      # SOA 6 marks the start of a zone of authority
      # MB 7 a mailbox domain name (EXPERIMENTAL)
      # MG 8 a mail group member (EXPERIMENTAL)
      # MR 9 a mail rename domain name (EXPERIMENTAL)
      # NULL 10 a null RR (EXPERIMENTAL)
      # WKS 11 a well known service description
      # PTR 12 a domain name pointer
      # HINFO 13 host information
      # MINFO 14 mailbox or mail list information
      # MX 15 mail exchange
      # TXT 16 text strings

      def qname
        parts[0]
      end

      def qclass
        parts[1]
      end

      def encoded_qclass
        {
          'IN' => 1,
          'CH' => 3,
          'HS' => 4
        }[qclass]
      end

      def qtype
        parts[2]
      end

      def encoded_qtype
        {
          'A'     => 1,
          'NS'    => 2,
          'CNAME' => 5,
          'SOA'   => 6,
          'PTR'   => 12,
          'HINFO' => 13,
          'MINFO' => 14,
          'MX'    => 15,
          'TXT'   => 16
        }[qtype]
      end

      def ttl
        parts[3].to_i
      end

      def rdata
        parts[4]
      end

      def encode_name name
        parts = name.split /\./
        parts.map! { |p| BinData::Uint8.new(p.length).to_binary_s + p }
        parts << BinData::Uint8.new(0).to_binary_s
        parts.join ''
      end

      def encoded_qname
        encode_name qname
      end

      def encoded_rdata
        # FIXME: Extract this case statment into separate encoders
        case qtype
        when 'A', 'PTR'
          parts = rdata.split /\./
          parts.map! { |o| BinData::Uint8.new(o.to_i).to_binary_s }
          parts.join ''
        when 'NS', 'CNAME'
          encode_name rdata
        else
          raise "I don't know how to encode QTYPE #{qtype.inspect}"
        end
      end

      def parts
        string = record_string.dup
        string.strip!
        parts = string.split /\s+/, 5
        parts.map! { |p| p.strip }
        parts
      end

      def execute
        self.record = Answer.new.tap { |a|
          a.qname = encoded_qname
          a.qtype = encoded_qtype
          a.qclass = encoded_qclass
          a.ttl = ttl
          a.rdata = encoded_rdata
        }
      end
    end

    def add record
      parser = RecordParser.new record
      parser.execute
      record = parser.record
      answers << record
    end

    def to_s
      [ header, question, *answers ].map { |part|
        part.to_binary_s
      }.join ''
    end
  end
end
