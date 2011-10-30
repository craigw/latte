module Latte
  class Query
    include Enumerable
    initialize_with :raw_query, :logger

    class Question
      initialize_with :wrapped_question

      def qname
	wrapped_question.qName
      end

      def qclass
	wrapped_question.qClass
      end

      def qtype
	wrapped_question.qType
      end

      def to_s
        wrapped_question.to_s
      end
    end

    def to_s
      packet.to_s
    end

    def <=> other
      to_s <=> other.to_s
    end

    def each
      questions.each do |q|
        question = Question.new q
        yield question
      end
    end
    alias_method :each_question, :each

    def id
      packet.header.id
    end

    def packet
      @packet ||= build_packet
    end

    def build_packet
      Net::DNS::Packet.parse raw_query
    end
    private :build_packet

    def questions
      packet.question
    end
    private :questions
  end
end
