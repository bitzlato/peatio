# encoding: UTF-8
# frozen_string_literal: true

# TODO: Rename to DepositAddress
class PaymentAddress < ApplicationRecord
  include Vault::EncryptedModel
  strip_attributes

  vault_lazy_decrypt!

  after_commit :enqueue_address_generation

  validates :address, uniqueness: { scope: :blockchain_id }, if: :address?

  vault_attribute :details, serialize: :json, default: {}
  vault_attribute :secret

  # TODO Migrate association from wallet to blockchain and remove Wallet.deposit*
  belongs_to :wallet
  belongs_to :member
  belongs_to :blockchain

  before_validation if: :address do
    if blockchain.present?
      self.address = address.downcase unless gateway.case_sensitive?
      self.address = CashAddr::Converter.to_cash_address(address) if gateway.supports_cash_addr_format?
    end
  end

  delegate :gateway, :currencies, to: :blockchain

  def enqueue_address_generation
    AMQP::Queue.enqueue(:deposit_coin_address, { member_id: member.id, blockchain_id: blockchain_id }, { persistent: true })
  end

  def format_address(format)
    format == 'legacy' ? to_legacy_address : to_cash_address
  end

  def to_legacy_address
    CashAddr::Converter.to_legacy_address(address)
  end

  def to_cash_address
    CashAddr::Converter.to_cash_address(address)
  end

  def status
    if address.present?
      blockchain.status # active or disabled
    else
      'pending'
    end
  end

  def trigger_address_event
    ::AMQP::Queue.enqueue_event('private', member.uid, :deposit_address,
                                type: :create,
                                currencies: currencies.codes,
                                address:  address)
  end

  def currency
    wallet.native_currency
  end
end
