# frozen_string_literal: true

class EthereumGateway
  class AbstractCommand
    include Concern

    attr_reader :client

    def initialize(client)
      @client = client || raise('No gateway client')
    end

    # ex calculate_gas_price
    def fetch_gas_price
      client.json_rpc(:eth_gasPrice, []).to_i(16).tap do |gas_price|
        Rails.logger.debug { "Fetched gas price #{gas_price}" }
      end
    end
  end
end
