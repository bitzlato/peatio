# encoding: UTF-8
# frozen_string_literal: true

# TODO: Rename to DepositAddress
class PaymentAddress < ApplicationRecord
  include Vault::EncryptedModel

  vault_lazy_decrypt!

  after_commit :enqueue_address_generation

  validates :address, uniqueness: { scope: :wallet_id }, if: :address?

  vault_attribute :details, serialize: :json, default: {}
  vault_attribute :secret

  # TODO Migrate association from wallet to blockchain and remove Wallet.deposit*
  belongs_to :wallet
  belongs_to :member

  before_validation do
    next if blockchain_api&.case_sensitive?
    self.address = address.try(:downcase)
  end

  before_validation do
    next unless address? && blockchain_api&.supports_cash_addr_format?
    self.address = CashAddr::Converter.to_cash_address(address)
  end

  def blockchain_api
    BlockchainService.new(wallet.blockchain)
  end

  def enqueue_address_generation
    AMQP::Queue.enqueue(:deposit_coin_address, { member_id: member.id, wallet_id: wallet.id }, { persistent: true })
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
      # In case when wallet was deleted and payment address still exists in DB
      wallet.present? ? wallet.status : ''
    else
      'pending'
    end
  end

  def trigger_address_event
    ::AMQP::Queue.enqueue_event('private', member.uid, :deposit_address, type: :create,
                          currencies: wallet.currencies.codes,
                          address:  address)
  end
end

# == Schema Information
# Schema version: 20210128083207
#
# Table name: payment_addresses
#
#  id                :integer          not null, primary key
#  member_id         :bigint
#  wallet_id         :bigint
#  address           :string(95)
#  remote            :boolean          default(FALSE), not null
#  secret_encrypted  :string(255)
#  details_encrypted :string(1024)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_payment_addresses_on_member_id  (member_id)
#  index_payment_addresses_on_wallet_id  (wallet_id)
#
