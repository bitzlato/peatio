# frozen_string_literal: true

# TODO: Rename to DepositAddress
class PaymentAddress < ApplicationRecord
  extend PaymentAddressTotals
  include BlockchainAddressConcern
  include Vault::EncryptedModel
  include AASM

  strip_attributes

  vault_lazy_decrypt!

  after_commit :enqueue_address_generation, on: :create

  validates :address, uniqueness: { scope: :blockchain_id }, if: :address?
  validates :blockchain_id, uniqueness: { scope: :member_id }, unless: :archived_at?

  vault_attribute :details, serialize: :json, default: {}
  vault_attribute :secret

  scope :by_address, ->(address) { where('lower(address)=?', address.downcase) }
  scope :with_balances, -> { where 'EXISTS ( SELECT * FROM jsonb_each_text(balances) AS each(KEY,val) WHERE "val"::decimal >= 0)' }
  scope :collection_required, -> { with_balances.where(collection_state: %i[none pending done]) }

  # TODO: Migrate association from wallet to blockchain and remove Wallet.deposit*
  belongs_to :member
  belongs_to :blockchain

  aasm :collection_state, namespace: :collection, whiny_transitions: true, requires_lock: true do
    state :none, initial: true
    state :pending
    state :collecting
    state :gas_refueling
    state :done

    event :collect do
      transitions from: %i[pending none done], to: :collecting do
        guard do
          last_transfer_try_at.nil? || last_transfer_try_at < 30.minutes.ago
        end
      end
      after do
        touch :last_transfer_try_at
      end
      after_commit do
        blockchain.gateway.collect! self
        touch :collected_at
        done!
      end
    end

    event :refuel_gas do
      transitions from: %i[pending none done], to: :gas_refueling do
        guard do
          last_transfer_try_at.nil? || last_transfer_try_at < 30.minutes.ago
        end
      end
      after do
        touch :last_transfer_try_at
      end
      after_commit do
        blockchain.gateway.refuel_gas! self
        touch :gas_refueled_at
        done!
      end
    end

    event :done do
      transitions from: %i[collecting gas_refueling], to: :done
    end
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

  def update_balances!
    Jobs::Cron::PaymentAddressBalancer.update_balances self
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

  def has_enough_gas_to_collect?
    blockchain.gateway.has_enough_gas_to_collect? address
  end

  # Balance reached amount limit to be collected
  def has_collectable_balances?
    blockchain.gateway.has_collectable_balances? address
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
