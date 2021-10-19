# frozen_string_literal: true

class BlockchainAddress < ApplicationRecord
  ADDRESS_TYPES = %w[ethereum].freeze

  strip_attributes

  vault_lazy_decrypt!
  vault_attribute :private_key

  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES }
  validates :address, uniqueness: { scope: :address_type }, if: :address?

  def decrypted_key
    Eth::Key.new priv: private_key
  end
end
