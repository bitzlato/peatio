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
  belongs_to :member
  belongs_to :blockchain

  before_validation if: :address do
    self.address = blockchain.normalize_address address if blockchain.present?
  end

  delegate :gateway, :currencies, to: :blockchain

  def enqueue_address_generation
    AMQP::Queue.enqueue(:deposit_coin_address, { member_id: member.id, blockchain_id: blockchain_id }, { persistent: true })
  rescue Bunny::ConnectionClosedError => err
    report_exception err, true, member_id: member.id, blockchain_id: blockchain_id
  end

  def explorer_url
  end

  def format_address(format)
    blockchain.gateway_class.format_address(address, format)
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
