# encoding: UTF-8
# frozen_string_literal: true

class Deposit < ApplicationRecord
  STATES = %i[submitted invoiced canceled rejected accepted skipped dispatched].freeze

  # TODO rename dispatched to completed
  #
  serialize :error, JSON unless Rails.configuration.database_support_json
  serialize :from_addresses, Array
  serialize :data, JSON unless Rails.configuration.database_support_json

  include AASM
  include TIDIdentifiable
  include FeeChargeable

  extend Enumerize
  TRANSFER_TYPES = { fiat: 100, crypto: 200 }

  belongs_to :currency, required: true, touch: false
  belongs_to :member, required: true
  belongs_to :blockchain, touch: false
  has_many :deposit_spreads

  acts_as_eventable prefix: 'deposit', on: %i[create update]

  scope :recent, -> { order(id: :desc) }

  before_validation on: :create do
    self.blockchain ||= self.currency.try(:blockchain)
  end

  before_create do
    self.blockchain ||= self.currency.blockchain || raise("No blockchain currency #{currency.id}") if currency.present?
  end
  before_validation { self.completed_at ||= Time.current if completed? }
  before_validation { self.transfer_type ||= currency.coin? ? 'crypto' : 'fiat' }

  validates :tid, presence: true, uniqueness: { case_sensitive: false }
  validates :aasm_state, :type, presence: true
  validates :completed_at, presence: { if: :completed? }
  validates :block_number, allow_blank: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :amount,
            numericality: {
              greater_than_or_equal_to:
                -> (deposit){ deposit.currency.min_deposit_amount }
            }, on: :create

  delegate :key, to: :blockchain, prefix: true

  aasm :collection_state, namespace: :collection, whiny_transitions: true, requires_lock: true do
    state :pending, initial: true
    state :processing
    state :collected
  end
  aasm whiny_transitions: true, requires_lock: true do
    state :submitted, initial: true
    state :invoiced
    state :canceled
    state :rejected
    state :accepted
    # state :aml_processing
    # state :aml_suspicious
    state :processing
    state :skipped
    # state :collected
    state :dispatched
    # state :fee_processing
    state :errored
    state :refunding
    event(:cancel) { transitions from: :submitted, to: :canceled }
    event(:reject) { transitions from: :submitted, to: :rejected }
    event :accept do
      transitions from: %i[submitted invoiced], to: :accepted
      after do
        if currency.coin? && (Peatio::App.config.deposit_funds_locked ||
                              Peatio::App.config.manual_deposit_approval)
          account.plus_locked_funds(amount)
        else
          account.plus_funds(amount)
        end
        record_submit_operations!
      end
    end
    event :skip do
      transitions from: :processing, to: :skipped
    end

    event :invoice do
      transitions from: :submitted, to: :invoiced
    end

    # Нет смысла сейчас собирать fee, делаем это отдельным процессом
    #event :process do
      #transitions from: %i[aml_processing aml_suspicious accepted errored], to: :aml_processing do
        #guard do
          #Peatio::AML.adapter.present? || Peatio::App.config.manual_deposit_approval
        #end

        #after do
          #process_collect! if aml_check!
        #end
      #end

      #transitions from: %i[accepted skipped errored], to: :processing do
        #guard { currency.coin? }
      #end
    #end

    #event :fee_process do
      #transitions from: %i[accepted processing skipped], to: :fee_processing do
        #guard { currency.coin? }
      #end
    #end

    #event :process_collect do
      #transitions from: %i[aml_processing aml_suspicious], to: :processing do
        #guard do
          #currency.coin? && (Peatio::AML.adapter.present? || Peatio::App.config.manual_deposit_approval)
        #end

        #after do
          #if !Peatio::App.config.deposit_funds_locked
            #account.unlock_funds(amount)
            #record_complete_operations!
          #end
        #end
      #end
    #end

    #event :aml_suspicious do
      #transitions from: :aml_processing, to: :aml_suspicious do
        #guard { Peatio::AML.adapter.present? || Peatio::App.config.manual_deposit_approval  }
      #end
    #end

    event :dispatch do
      transitions from: %i[errored accepted], to: :dispatched
      after do
        if Peatio::App.config.deposit_funds_locked
          account.unlock_funds(amount)
          record_complete_operations!
        end
      end
    end

    event :refund do
      transitions from: %i[skipped], to: :refunding do
        guard { currency.coin? }
      end
    end
  end

  def aml_check!
    # If there is no AML adapter on a platform and manual deposit approval enabled
    # system will return nil value to not proceed with automatic deposit collection in aml cron job
    return nil if Peatio::App.config.manual_deposit_approval && Peatio::AML.adapter.blank?

    from_addresses.each do |address|
      result = Peatio::AML.check!(address, currency_id, member.uid)
      if result.risk_detected
        aml_suspicious!
        return nil
      end
      return nil if result.pending
    end
    true
  end

  delegate :gateway, to: :blockchain

  def transfer_links
    # TODO rename data['links'] to transfer_links
    # TODO rename data['expires_at'] to expires_at
    # TODO Use txid instead of invoice_id
    data&.fetch 'links', []
  end

  def confirmations
    return 0 if block_number.blank?
    return blockchain.processed_height - block_number if (blockchain.processed_height - block_number) >= 0
    'N/A'
  rescue StandardError => e
    report_exception(e)
    'N/A'
  end

  def add_error(e)
    if error.blank?
      update!(error: [{ class: e.class.to_s, message: e.message }])
    else
      update!(error: error << { class: e.class.to_s, message: e.message })
    end
  end

  #def spread_between_wallets!
    #return false if spread.present?
    #update! spread: DepositSpreader.call(self).map(&:as_json)
  #end

  #def spread_transactions_ids
    #spread.map { |s| s.fetch(:hash) }
  #end

  def account
    member&.get_account(currency)
  end

  def uid
    member&.uid
  end

  def uid=(uid)
    self.member = Member.find_by_uid(uid)
  end

  def payment_address
    member.payment_address blockchain
  end

  def as_json_for_event_api
    { tid:                      tid,
      user:                     { uid: member.uid, email: member.email },
      uid:                      member.uid,
      currency:                 currency_id,
      amount:                   amount.to_s('F'),
      state:                    aasm_state,
      blockchain_state:         blockchain.status,
      created_at:               created_at.iso8601,
      updated_at:               updated_at.iso8601,
      completed_at:             completed_at&.iso8601,
      blockchain_address:       address,
      blockchain_txid:          txid }
  end

  def completed?
    !submitted?
  end

  def enqueue_deposit_intention!
    AMQP::Queue.enqueue(:deposit_intention, { deposit_id: id }, { persistent: true })
  end

  def process!
    # только для совместимости
    # TODO удалить
  end

  def money_amount
    currency.money_currency.to_money_from_decimal amount
  end

  def money_amount=(value)
    raise 'must be Money' unless value.is_a? Money
    self.amount = value.to_d
  end

  private

  # Creates dependant operations for deposit.
  def record_submit_operations!
    transaction do
      # Credit main fiat/crypto Asset account.
      Operations::Asset.credit!(
        amount: amount + fee,
        currency: currency,
        reference: self
      )

      # Credit main fiat/crypto Revenue account.
      Operations::Revenue.credit!(
        amount: fee,
        currency: currency,
        reference: self,
        member_id: member_id
      )

      locked_kind_check = currency.coin? && (Peatio::App.config.deposit_funds_locked || Peatio::App.config.manual_deposit_approval)
      kind = locked_kind_check ? :locked : :main
      # Credit locked fiat/crypto Liability account.
      Operations::Liability.credit!(
        amount: amount,
        currency: currency,
        reference: self,
        member_id: member_id,
        kind: kind
      )
    end
  end

  # Creates dependant operations for complete deposit.
  def record_complete_operations!
    transaction do
      Operations::Liability.transfer!(
        amount:     amount,
        currency:   currency,
        reference:  self,
        from_kind:  :locked,
        to_kind:    :main,
        member_id:  member_id
      )
    end
  end
end
