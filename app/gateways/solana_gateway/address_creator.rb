# frozen_string_literal: true

class SolanaGateway
  class AddressCreator
    def self.perform secret=nil
      key = Solana::Key.new
      blockchain_address = BlockchainAddress.create!({
                                                       address: key.address,
                                                       address_type: SolanaGateway.address_type,
                                                       private_key_hex: key.private_hex
                                                     })
      { address: blockchain_address.address }
    end
  end
end