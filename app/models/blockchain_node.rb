class BlockchainNode < ApplicationRecord
  include GatewayConcern
  include Vault::EncryptedModel

  belongs_to :blockchain

  vault_lazy_decrypt!
  vault_attribute :server
end
