class BelomorGateway < AbstractGateway
  def client_version
  end

  def latest_block_number
  end

  def create_address!
  end

  ## Stage 2
  #
  def create_transaction!(from_address:,
                          to_address:,
                          amount:,
                          blockchain_address: nil,
                          contract_address: nil,
                          subtract_fee: false, # nil means auto
                          nonce: nil,
                          gas_factor: nil,
                          meta: {}) # rubocop:disable Lint/UnusedMethodArgument

  end
end
