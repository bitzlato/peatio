class EthereumGateway
  module Concern
    def valid_address?(address)
      AdequateCryptoAddress.valid? address, :ethereum
    end

    def normalize_address(address)
      AdequateCryptoAddress.address(address, :eth).address.downcase
    end

    def normalize_txid(txid)
      return nil if txid.nil?

      txid.to_s.downcase
    end

    def valid_txid?(txid)
      txid.to_s.match?(/\A0x[A-F0-9]{64}\z/i)
    end

    def normalize_txid(id)
      id.downcase
    end

    def validate_txid!(txid)
      unless valid_txid? txid
        raise Ethereum::Client::Error, \
              "Transaction failed (invalid txid #{txid})."
      end
      txid
    end
  end
end
