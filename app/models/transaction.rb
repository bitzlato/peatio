class Transaction < ApplicationRecord
  include TransactionKindDefiner
  include TransactionReferences

  upsert_keys %i[blockchain_id txid txout]

  # == Constants ============================================================

  SUCCESS_STATUS = 'success'
  FAIL_STATUS = 'failed'
  STATUSES = [SUCCESS_STATUS, FAIL_STATUS].freeze

  # == Attributes ===========================================================

  # == Relationships ========================================================

  belongs_to :reference, polymorphic: true
  belongs_to :currency
  belongs_to :blockchain

  STATUSES.each do |status|
    scope status, -> { where status: status }
  end

  scope :by_address, ->(address) { where 'lower(from_address) = ? or lower(to_address) = ?', address.downcase, address.downcase }
  # == Validations ==========================================================

  validates :currency, :amount, :from_address, :status, presence: true

  # In ethereum there can be no to_addres if this failed contract transaction
  validates :to_address, presence: true, unless: :failed?
  validates :txout, presence: true, unless: :failed?

  validates :status, inclusion: { in: STATUSES }

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  after_initialize :initialize_defaults, if: :new_record?

  before_validation do
    self.kind = define_kind
    self.direction = define_direction
  end
  before_save do
    update_reference
  end

  KINDS = %w(refill internal gas_refuel withdraw unauthorized_withdraw deposit collection unknown)
  enum kind: KINDS, _prefix: true
  validates :kind, presence: true, inclusion: { in: kinds.keys }

  ADDRESS_KINDS = { unknown: 1, wallet: 2, deposit: 3, absence: 4 }
  enum to: ADDRESS_KINDS, _prefix: true
  enum from: ADDRESS_KINDS, _prefix: true

  DIRECTIONS = { unknown: 0, income: 1, outcome: 2, internal: 3, failed: 4 }
  enum direction: DIRECTIONS, _prefix: true

  validates :to, inclusion: { in: tos.keys }
  validates :to, presence: true, unless: :failed?
  validates :from, presence: true, inclusion: { in: froms.keys }
  validates :direction, presence: true, inclusion: { in: directions.keys }

  # TODO: record expenses for succeed transactions

  # Upsert transaction from blockchain
  def self.upsert_transaction!(tx, extra = {})
    raise 'transaction must be a Peatio::Transaction' unless tx.is_a? Peatio::Transaction
    raise 'transaction amount must be a Money' unless tx.amount.is_a? Money
    raise 'transaction fee must be nil or a Money' unless tx.fee.nil? || tx.fee.is_a?(Money)
    # TODO just now created transaction has no txout. Available to change txout from nil to number

    attrs = {
      fee:             tx.fee.nil? ? nil : tx.fee.to_d,
      fee_currency_id: tx.fee_currency_id,
      block_number:    tx.block_number,
      status:          tx.status,
      txout:           tx.txout, # change nil to zero
      from_address:    tx.from_address,
      from:            tx.from || raise('No "from" kind in tx'),
      amount:          tx.amount.nil? ? nil : tx.amount.to_d,
      to_address:      tx.to_address,
      to:              tx.to || raise('No "to" kind in tx'),
      currency_id:     tx.currency_id,
      blockchain_id:   tx.blockchain_id,
      txid:            tx.id,
      options:         tx.options
    }.deep_merge(extra)

    # TODO There are problem with save 'kind'a attribuve with upsert
    #
    t = find_by(blockchain_id: tx.blockchain_id, txid: tx.txid, txout: tx.txout)
    if t.nil?
      t = Transaction.create!(attrs)
    else
      t.update! attrs
    end
    Rails.logger.debug { "Transaction #{tx.txid}/#{tx.txout} is saved to database with id=#{t.id}" }
    t
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordInvalid => err
    report_exception err, true, tx: tx, record: err.record.as_json
    raise err
  rescue ActiveRecord::RecordNotUnique => err
    report_exception err, true, tx: tx, record: err.message
    raise err
  end

  def refetch!
    blockchain.service.refetch_and_update_transaction! txid, txout
    reload
  end

  def failed?
    status == FAIL_STATUS
  end

  def success?
    status == SUCCESS_STATUS
  end

  def initialize_defaults
    self.status = :pending if status.blank?
  end

  def transaction_url
    blockchain.explore_transaction_url txid if blockchain
  end
end
