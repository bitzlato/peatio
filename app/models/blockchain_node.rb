class BlockchainNode < ApplicationRecord
  include GatewayConcern
  include Vault::EncryptedModel

  vault_lazy_decrypt!
  vault_attribute :server

  belongs_to :blockchain

  validates :server, url: true, presence: true
end
