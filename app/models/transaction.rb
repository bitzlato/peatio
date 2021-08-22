class Transaction < ApplicationRecord
  # TODO change currency_id to blockchain_id
  upsert_keys [:currency_id, :txid]

  # == Constants ============================================================

  PENDING_STATUS = 'pending'
  SUCCESS_STATUS = 'success'
  FAIL_STATUS = 'failed'
  STATUSES = [PENDING_STATUS, SUCCESS_STATUS, FAIL_STATUS].freeze

  # == Attributes ===========================================================

  # == Extensions ===========================================================

  serialize :data, JSON unless Rails.configuration.database_support_json

  # == Relationships ========================================================

  belongs_to :reference, polymorphic: true
  belongs_to :currency
  has_one :blockchain, through: :currency

  STATUSES.each do |status|
    scope status, -> { where status: status }
  end

  # == Validations ==========================================================

  validates :currency, :amount, :from_address, :status, presence: true

  # In ethereum there can be no to_addres if this failed contract transaction
  validates :to_address, presence:true, unless: :failed?

  validates :status, inclusion: { in: STATUSES }

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  after_initialize :initialize_defaults, if: :new_record?

  # TODO: record expenses for succeed transactions

  def self.create_from_blockchain_transaction!(tx, extra = {})
    create!(
      {
        from_address: tx.from_address,
        to_address: tx.to_address,
        currency_id: tx.currency_id,
        txid: tx.txid,
        block_number: tx.block_number,
        amount: tx.amount,
        status: tx.status,
        txout: tx.txout,
        options: tx.options,
      }.deep_merge(extra)
    )
  end

  def failed?
    status == FAIL_STATUS
  end

  def initialize_defaults
    self.status = :pending if status.blank?
  end

  def transaction_url
    blockchain.explore_transaction_url txid if blockchain
  end

  # TODO Validate txid by blockchain
end
