# frozen_string_literal: true

module BlockchainAddressConcern
  def blockchain_address
    return nil if blockchain.address_type.nil?

    BlockchainAddress
      .find_by(address: address, address_type: blockchain.address_type)
  end

  def private_key
    blockchain_address.try(:private_key)
  end
end
