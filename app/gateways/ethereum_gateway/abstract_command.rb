class EthereumGateway
  class AbstracttCommand
    include NumericHelpers

    attr_reader :client

    def initialize(client)
      @client = client || raise("No gateway client")
    end
  end
end
