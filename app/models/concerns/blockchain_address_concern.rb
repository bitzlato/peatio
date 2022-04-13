# frozen_string_literal: true

module BlockchainAddressConcern
  def blockchain_address
    return nil if blockchain.address_type.nil?

    BlockchainAddress
      .find_by(address: address, address_type: blockchain.address_type)
  end

  def private_key
    return nil if blockchain_address.nil?

    blockchain.private_key(blockchain_address.private_key_hex)
  end
end
