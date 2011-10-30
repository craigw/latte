module Latte
  class Server
    CHECK_ALIVE_INTERVAL = 5

    initialize_with :resolver, :logger
    default_value_of :resolver, lambda { |*| }
    default_value_of :logger    do NullLogger.instance end
    private_attr_accessor :children
    default_value_of :children, {}
    private_attr_accessor :addresses
    default_value_of :addresses do [ Address.default ] end

    def listen_on *addresses
      return if addresses.empty?
      self.addresses = addresses
    end

    def run
      logger.debug "I will listen on #{addresses.map(&:to_s).join(',')}"
      listen
    end

    def listen
      loop do
        addresses.each do |address|
          next if running_server? address
          run_server address
        end
        sleep CHECK_ALIVE_INTERVAL
      end
    end
    private :listen

    def running_server? address
      return false unless server_exists_for? address
      server = server_for address
      server.alive?
    end

    def server_for address
      children[address]
    end

    def server_exists_for? address
      !server_for(address).nil?
    end

    def run_server address
      if server_exists_for? address
        logger.warn "Restarting server for #{address}"
      end
      logger.debug "Preparing server for #{address}"
      server_loop = "#{address.protocol}_server_loop"
      children[address] = Thread.new do
        begin
          logger.debug "Server starting on #{address}"
          Socket.send server_loop, address.ip_address, address.port do |data, client|
            Thread.new do
              begin
                query = Query.new data
                client_name = client.remote_address.ip_unpack.join ':'
                logger.info "#{client_name} > #{address}: Received query:\n#{query}"
                logger.debug "#{client_name} > #{address}: Packet: #{HexPresenter.new(data)}"
                response = Response.new query, logger
                query.each_question do |question|
                  resolver.call question, response
                end
                answer = response.data
                logger.info "#{client_name} < #{address}: Sending repsonse:\n#{response}"
                logger.debug "#{client_name} < #{address}: Packet: #{HexPresenter.new(answer)}"
                client.reply answer
              rescue => e
                logger.error [ e.message, e.backtrace ].flatten.join("\n")
              end
            end
          end
          logger.warn "Server loop terminated"
        rescue => e
          logger.error [ e.message, e.backtrace ].flatten.join("\n")
        end
      end
      logger.debug "Server started for #{address}"
    end
    private :run_server
  end
end
