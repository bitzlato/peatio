class Transaction < ApplicationRecord
  upsert_keys [:blockchain_id, :txid, :txout]

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
  belongs_to :blockchain

  STATUSES.each do |status|
    scope status, -> { where status: status }
  end

  # == Validations ==========================================================

  validates :currency, :amount, :from_address, :status, presence: true

  # In ethereum there can be no to_addres if this failed contract transaction
  validates :to_address, presence: true, unless: :failed?
  validates :txout, presence: true, unless: :failed?

  validates :status, inclusion: { in: STATUSES }

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  after_initialize :initialize_defaults, if: :new_record?

  before_save do
    self.txout ||= 0 # Because of unique index
    self.kind = define_kind
  end
  before_save :update_reference!

  KINDS = %w(refill internal gas_refuel withdraw unauthorized_withdraw deposit collection unknown)
  enum kind: KINDS

  ADDRESS_KINDS = { unknown: 1, wallet: 2, deposit: 3, absence: 4 }
  enum to: ADDRESS_KINDS, _prefix: true
  enum from: ADDRESS_KINDS, _prefix: true

  # TODO: record expenses for succeed transactions

  # Upsert transaction from blockchain
  def self.upsert_transaction!(tx, extra = {})
    raise 'transaction must be a Peatio::Transaction' unless tx.is_a? Peatio::Transaction
    raise 'transaction amount must be a Money' unless tx.amount.is_a? Money
    raise 'transaction fee must be nil or a Money' unless tx.fee.nil? || tx.fee.is_a?(Money)
    # TODO just now created transaction has no txout. Available to change txout from nil to number
    Transaction.upsert!(
      {
        fee:               tx.fee.nil? ? nil : tx.fee.to_d,
        fee_currency_id:   tx.fee_currency_id,
        block_number:      tx.block_number,
        status:            tx.status,
        txout:             tx.txout.to_i, # change nil to zero
        from_address:      tx.from_address,
        from: tx.from,
        amount:            tx.amount.nil? ? nil : tx.amount.to_d,
        to_address:        tx.to_address,
        to:   tx.to,
        currency_id:       tx.currency_id,
        blockchain_id:     tx.blockchain_id,
        txid:              tx.id,
        options:           tx.options
      }.deep_merge(extra)
    ).tap do |t|
      Rails.logger.debug("Transaction #{tx.txid}/#{tx.txout} is saved to database with id=#{t.id}")
    end
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => err
    report_exception err, true, tx: tx, record: err.record.as_json
    raise err
  end

  def define_kind
    if to_deposit?
      if from_wallet?
        :gas_refuel
      elsif from_deposit?
        :internal
      elsif from_unknown?
        :deposit
      else
        :unknown
      end
    elsif to_wallet?
      if from_deposit?
        :collection
      elsif from_wallet?
        :internal
      elsif from_unknown?
        :refill
      else
        :unknown
      end
    elsif to_unknown?
      if from_wallet?
        :withdraw
      elsif from_deposit?
        :unauthorized_withdraw
      else
        :unknown
      end
    else
      :unknown
    end
  end


  def refetch!
    blockchain.service.refetch_and_update_transaction! txid, txout
    reload
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

  def update_reference!
    if reference.is_a? Withdraw
      reference.update! txid: txid, txout: txout if reference.txid.nil?
    elsif reference.is_a? Deposit
      reference.update! txid: txid, txout: txout if reference.txid.nil? || (reference.txout.nil? && txout.present?)
    elsif reference.nil?
      wallet = (from_address.present? ? Wallet.find_by_address(from_address) : nil) || (to_address.present? ? Wallet.find_by_address(to_address) : nil )
      self.reference = wallet if wallet.present?
    else
      report_exception "Can't detect transction reference #{id}", true, { id: id, txid: txid }
    end
  end

  # TODO Validate txid by blockchain
end
