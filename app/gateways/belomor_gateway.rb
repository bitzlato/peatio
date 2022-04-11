# frozen_string_literal: true

class BelomorGateway < AbstractGateway
  def client_version; end

  def latest_block_number; end

  def create_address!; end

  ## Stage 2
  #
  def create_transaction!(from_address:, to_address:, amount:, blockchain_address: nil, contract_address: nil, subtract_fee: false, nonce: nil, gas_factor: nil, meta: {}); end
end
