# frozen_string_literal: true

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

    def normalize_txid(id)
      id.downcase
    end
  end
end
