# frozen_string_literal: true

require 'belomor_client'

class BelomorAbstractGateway < AbstractGateway
  def create_address!
    client.create_address
  end

  def client_version
    client.client_version.fetch('client_version')
  end

  def latest_block_number
    client.latest_block_number.fetch('latest_block_number')
  end

  private

  def build_client
    BelomorClient.new(api_url: blockchain.server, network_type: self.class::NETWORK_TYPE)
  end

  ## Stage 2
  #
  def create_transaction!(from_address:, to_address:, amount:, blockchain_address: nil, contract_address: nil, subtract_fee: false, nonce: nil, gas_factor: nil, meta: {}); end
end
