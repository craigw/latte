module Latte
  class CommandLine
    initialize_with :arguments

    def parse_arguments
      parsed = { addresses: [] }
      OptionParser.new do |o|
        o.on '-l', '--listen ADDRESS', 'Serve DNS on this address' do |addr|
          address = Address.new addr
          parsed[:addresses] << address
          parsed[:addresses].uniq!
        end

        o.separator ''
        o.separator 'Common options:'

        o.on_tail '-h', '--help', 'Show this message' do
          puts o
          exit
        end

        o.on_tail '--version', 'Show version' do
          puts Latte::VERSION
          exit
        end
      end.parse arguments
      OpenStruct.new parsed
    end

    def execute
require 'logger'
      arguments = parse_arguments
      server = Latte::Server.new Logger.new(STDOUT)
      server.listen_on *arguments.addresses
      server.run
    end
  end
end
