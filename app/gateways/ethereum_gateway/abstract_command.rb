class EthereumGateway
  class AbstractCommand
    include NumericHelpers

    attr_reader :client

    def initialize(client)
      @client = client || raise("No gateway client")
    end

    private

    def normalize_address(address)
      address.downcase
    end

    def normalize_txid(txid)
      txid.downcase
    end

    def valid_txid?(txid)
      txid.to_s.match?(/\A0x[A-F0-9]{64}\z/i)
    end
  end
end
