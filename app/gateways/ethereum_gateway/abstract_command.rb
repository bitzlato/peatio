class EthereumGateway
  class AbstractCommand
    include NumericHelpers
    STATUS_SUCCESS = '0x1'
    STATUS_FAILED = '0x0'
    ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

    attr_reader :client

    def initialize(client)
      @client = client || raise("No gateway client")
    end

    private

    def transaction_status(block_txn)
      if block_txn.dig('status') == STATUS_SUCCESS
        Transaction::SUCCESS_STATUS
      elsif block_txn.dig('status') == STATUS_FAILED
        Transaction::FAIL_STATUS
      else
        Transaction::PENDING_STATUS
      end
    end

    def logger
      Rails.logger
    end

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
