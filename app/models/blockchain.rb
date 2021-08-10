# encoding: UTF-8
# frozen_string_literal: true

# Rename to Gateway
#
class Blockchain < ApplicationRecord
  include GatewayConcern
  include Vault::EncryptedModel

  vault_lazy_decrypt!
  vault_attribute :server

  has_many :currencies
  has_many :wallets
  has_many :whitelisted_smart_contracts

  validates :key, :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active disabled] }
  validates :height,
            :min_confirmations,
            numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :server, url: { allow_blank: true }
  before_create { self.key = self.key.strip.downcase }

  scope :active, -> { where(status: :active) }

  def explorer=(hash)
    write_attribute(:explorer_address, hash.fetch('address'))
    write_attribute(:explorer_transaction, hash.fetch('transaction'))
  end

  def supports_cash_addr_format?
    implements? :cash_addr
  end

  def status
    super&.inquiry
  end

  def active?
    status.active?
  end

  # The latest block which blockchain worker has processed
  def processed_height
    height + min_confirmations
  end
end
