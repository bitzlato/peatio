module WS
  module Ethereum
    class AbstractService
      include Helpers

      attr_reader :client

      def initialize(client)
        @client = client
      end
    end
  end
end
