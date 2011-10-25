module Latte
  class Query
    # QTTYPE codes:
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

    initialize_with :raw_query

    # DNS MESSAGE FORMAT
    #
    # Header
    # Question
    # Answer
    # Authority
    # Additional
    #
    # DNS HEADER FORMAT
    #
    # OCTET 1,2             ID
    # OCTET 3,4             QR(1 bit) + OPCODE(4 bit)+ AA(1 bit) + TC(1 bit) +
    #                       RD(1 bit)+ RA(1 bit) + Z(3 bit) + RCODE(4 bit)
    # OCTET 5,6             QDCOUNT
    # OCTET 7,8             ANCOUNT
    # OCTET 9,10            NSCOUNT
    # OCTET 11,12           ARCOUNT
    #
    # QUESTION FORMAT
    #
    # OCTET 1,2,…n          QNAME
    # OCTET n+1,n+2         QTYPE
    # OCTET n+3,n+4         QCLASS
    #
    # ANSWER, AUTHORITY, ADDITIONAL FORMAT
    #
    # OCTET 1,2,..n         NAME
    # OCTET n+1,n+2         TYPE
    # OCTET n+3,n+4         CLASS
    # OCTET n+5,n+6,n+7,n+8 TTL
    # OCTET n+9,n+10        RDLENGTH
    # OCTET n+11,n+12,…..   RDATA
    class QueryHeader < BinData::Record
      endian :big
      uint16 :id
      bit1   :qr
      bit4   :opcode
      bit1   :aa
      bit1   :tc
      bit1   :rd
      bit1   :ra
      bit3   :z
      bit4   :rcode
      uint16 :qdcount
      uint16 :ancount
      uint16 :nscount
      uint16 :arcount
    end

    class QueryRequest < QueryHeader
      stringz :qname
      uint16 :qtype
      uint16 :qclass
    end

    def parsed_header
      @parsed_header ||= build_header
    end
    private :parsed_header

    def build_header
      QueryHeader.read raw_query
    end
    private :build_header

    def parsed_record
      @parsed_record ||= build_record
    end
    private :parsed_record

    def build_record
      case parsed_header.qr.value
      when 0
        QueryRequest.read raw_query
      else
        raise "Unhandled QR value: #{parsed_header.qr.value}"
      end
    end

    def method_missing *args
      result = parsed_record.send *args
      return result.value if result.respond_to? :value
      result
    end

    def header
      "ID=#{id} QR=#{qr} TC=#{tc} RD=#{rd} RA=#{ra} Z=#{z} " + \
      "RCODE=#{rcode} QDCOUNT=#{qdcount} ANCOUNT=#{ancount} " + \
      "NSCOUNT=#{nscount} ARCOUNT=#{arcount}"
    end

    def human_qname
      value = parsed_record.qname.value.dup
      value.gsub! /^[\x00-\x1f]/, ''
      value.gsub! /[\x00-\x1f]/, '.'
      value + '.'
    end

    def query
      "QNAME=#{human_qname} QTYPE=#{qtype} QCLASS=#{qclass}"
    end

    def to_s
      [ header, query ].join " "
    end
  end
end
