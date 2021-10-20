# frozen_string_literal: true

class BlockchainAddress < ApplicationRecord
  include Vault::EncryptedModel
  ADDRESS_TYPES = %w[ethereum].freeze

  strip_attributes

  vault_lazy_decrypt!
  vault_attribute :private_key_hex

  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES }
  validates :address, presence: true, uniqueness: { scope: :address_type }

  def private_key
    Eth::Key.new priv: private_key_hex
  end
end
