# frozen_string_literal: true

# TODO: Rename to DepositAddress
class PaymentAddress < ApplicationRecord
  extend PaymentAddressTotals
  include AASM

  TRANSACTION_SLEEP_MINUTES = 15

  strip_attributes

  after_commit :enqueue_address_generation, on: :create, unless: :parent_id?

  validates :address, uniqueness: { scope: :blockchain_id }, if: :address?
  validates :blockchain_currency, presence: true, if: :parent_id?

  scope :by_address, ->(address) { where('lower(address)=?', address.downcase) }
  scope :active, -> { where(archived_at: nil) }

  # TODO: Migrate association from wallet to blockchain and remove Wallet.deposit*
  belongs_to :member
  belongs_to :blockchain
  belongs_to :parent, class_name: 'PaymentAddress', optional: true
  has_many :token_addresses, class_name: 'PaymentAddress', foreign_key: :parent_id
  belongs_to :blockchain_currency, optional: true

  aasm :collection_state, namespace: :collection, whiny_transitions: true, requires_lock: true do
    state :none, initial: true
    state :pending
    state :collecting
    state :gas_refueling
    state :done
  end

  before_validation if: :address do
    self.address = blockchain.normalize_address address if blockchain.present?
  end

  delegate :gateway, :currencies, to: :blockchain

  def self.find_by_address(address)
    where('lower(address)=?', address.downcase).take
  end

  def enqueue_address_generation(force: false)
    # Don't enqueue too often
    if !force && enqueued_generation_at.present? && enqueued_generation_at > 1.hour.ago
      Rails.logger.info("Skip enqueue_address_generation for member_id: #{member_id}, blockchain_id: #{blockchain_id} (last time enqueued #{enqueued_generation_at})")
      return
    end

    Rails.logger.info("enqueue_address_generation for member_id: #{member_id}, blockchain_id: #{blockchain_id}")
    touch :enqueued_generation_at
    AMQP::Queue.enqueue(:deposit_coin_address, { member_id: member.id, blockchain_id: blockchain_id }) unless ENV.true?('DISABLE_DEPOSIT_COIN_ADDRESS')
  rescue Bunny::ConnectionClosedError => e
    report_exception e, true, member_id: member.id, blockchain_id: blockchain_id
  end

  def address_url
    blockchain&.explore_address_url address
  end

  def status
    if address.present?
      blockchain.status # active or disabled
    else
      'pending'
    end
  end

  def transactions
    if address.nil?
      Transaction.none
    else
      return Transaction.none if blockchain.nil?

      # TODO: blockchain normalize
      blockchain.transactions.by_address(address.downcase)
    end
  end

  def trigger_address_event
    ::AMQP::Queue.enqueue_event('private', member.uid, :deposit_address,
                                type: :create,
                                currencies: currencies.codes,
                                address: address)
  end

  def currency
    wallet.native_currency
  end
end
