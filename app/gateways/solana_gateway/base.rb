# frozen_string_literal: true

class SolanaGateway
  class Base
    attr_reader :blockchain

    delegate :gateway, to: :blockchain
    delegate :api, to: :gateway

    def initialize blockchain
      @blockchain = blockchain
    end

    def logger
      Rails.logger
    end

    def kind_of_address(address)
      if address.is_a?(Enumerable)
        raise 'multiple addresses' if address.many?

        address = address.first
      end
      return :wallet if address.in? blockchain.wallets_addresses
      return :deposit if address.in? blockchain.deposit_addresses

      :unknown
    end
  end
end
