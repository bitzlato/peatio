# frozen_string_literal: true

class Withdraw < ApplicationRecord
  COMPLETED_STATES = %i[succeed rejected canceled failed].freeze
  SUCCEED_PROCESSING_STATES = %i[prepared accepted skipped processing errored confirming succeed under_review].freeze

  include AASM
  include TIDIdentifiable
  include FeeChargeable

  alias_attribute :to_address, :rid

  extend Enumerize

  serialize :error, JSON unless Rails.configuration.database_support_json
  serialize :metadata, JSON unless Rails.configuration.database_support_json

  belongs_to :blockchain, optional: false, touch: false
  belongs_to :currency, optional: false, touch: false
  belongs_to :member, optional: false, touch: false

  # Optional beneficiary association gives ability to support both in-peatio
  # beneficiaries and managed by third party application.
  belongs_to :beneficiary, optional: true

  acts_as_eventable prefix: 'withdraw', on: %i[create update]

  enumerize :transfer_type, in: WITHDRAW_TRANSFER_TYPES

  after_initialize :initialize_defaults, if: :new_record?
  before_validation(on: :create) { self.rid ||= beneficiary.rid if beneficiary.present? }
  before_validation { self.completed_at ||= Time.current if completed? }
  before_validation { self.transfer_type ||= currency.coin? ? 'crypto' : 'fiat' }
  after_commit :trigger_private_event

  # TODO: validate rid by blockchain specs
  #
  validates :rid, :aasm_state, presence: true
  validates :block_number, allow_blank: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :amount,
            presence: true,
            numericality: { greater_than_or_equal_to: ->(withdraw) { withdraw.currency.min_withdraw_amount } }
  validates :network_fee, allow_blank: true, numericality: { greater_than: 0 }

  validate on: :create do
    errors.add(:beneficiary, 'not active') if beneficiary.present? && !beneficiary.active? && !aasm_state.to_sym.in?(COMPLETED_STATES)
  end

  validate on: :create, if: ->(w) { w.currency.present? && w.currency.coin? } do
    errors.add(:rid, 'invalid address') unless blockchain.valid_address?(rid)
  end

  scope :completed, -> { where(aasm_state: COMPLETED_STATES) }
  scope :succeed_processing, -> { where(aasm_state: SUCCEED_PROCESSING_STATES) }
  scope :last_24_hours, -> { where('created_at > ?', 24.hours.ago) }
  scope :last_1_month, -> { where('created_at > ?', 1.month.ago) }

  aasm whiny_transitions: true, requires_lock: true do
    state :prepared, initial: true
    state :accepted
    state :canceled
    state :skipped
    state :to_reject
    state :rejected
    state :processing
    state :transfering
    state :under_review
    state :succeed
    state :failed
    state :errored
    state :confirming

    event :accept do
      transitions from: :prepared, to: :accepted do
        guard do
          member.withdraw_enabled?
        end
      end
      after do
        account.lock_funds(sum)
        update!(is_locked: true)
        record_submit_operations!
      end
      after_commit do
        # auto process withdrawal if sum less than limits and WITHDRAW_ADMIN_APPROVE env set to false (not set)
        process! if verify_limits && ENV.false?('WITHDRAW_ADMIN_APPROVE') && currency.coin?
      end
    end

    event :process do
      transitions from: %i[accepted skipped errored], to: :processing do
        guard do
          member.withdraw_enabled?
        end
      end
      after_commit do
        send_coins!
      end
    end

    event :cancel do
      transitions from: %i[prepared], to: :canceled
      transitions from: %i[accepted], to: :canceled do
        after do
          account.unlock_funds(sum)
          update!(is_locked: false)
          record_cancel_operations!
        end
      end
    end

    event :reject do
      transitions from: %i[to_reject accepted confirming under_review], to: :rejected
      after do
        account.unlock_funds(sum)
        update!(is_locked: false)
        record_cancel_operations!
      end
    end

    event :transfer do
      transitions from: %i[processing], to: :transfering
    end

    event :review do
      transitions from: :processing, to: :under_review
    end

    # Transfered to blockchain
    event :dispatch do
      transitions from: :transfering, to: :confirming do
        # Validate txid presence on coin withdrawal dispatch.
        guard do
          currency.fiat? || txid?
        end
      end
    end

    event :success do
      transitions from: %i[processing confirming], to: :succeed do
        guard do
          currency.fiat? || txid?
        end
        after do
          account.unlock_and_sub_funds(sum)
          update!(is_locked: false)
          record_complete_operations!
        end
      end
    end

    event :manual_success do
      transitions from: %i[transfering confirming errored under_review], to: :succeed do
        guard do
          currency.fiat? || txid?
        end
        after do
          account.unlock_and_sub_funds(sum)
          update!(is_locked: false)
          record_complete_operations!
        end
      end
    end

    event :skip do
      transitions from: :processing, to: :skipped
    end

    event :fail do
      transitions from: %i[transfering processing confirming skipped errored under_review], to: :failed
      after do
        account.unlock_funds(sum)
        update!(is_locked: false)
        record_cancel_operations!
      end
    end

    event :err do
      transitions from: %i[processing transfering], to: :errored, after: :add_error
    end
  end

  class << self
    def sanitize_execute_sum_queries(member_id, id = nil)
      sum_query =
        'SELECT sum(w.sum * c.price) as sum FROM withdraws as w ' \
        'INNER JOIN currencies as c ON c.id=w.currency_id ' \
        'where w.member_id = ? AND w.aasm_state IN (?) AND w.created_at > ?'
      params_24h = [member_id, SUCCEED_PROCESSING_STATES, 24.hours.ago]
      params_1m = [member_id, SUCCEED_PROCESSING_STATES, 1.month.ago]
      if id.present?
        sum_query = "#{sum_query} AND w.id <> ?"
        params_24h << id
        params_1m << id
      end
      squery_24h = ActiveRecord::Base.sanitize_sql_for_conditions([sum_query, *params_24h])
      squery_1m = ActiveRecord::Base.sanitize_sql_for_conditions([sum_query, *params_1m])
      sum_withdraws_24_hours = ActiveRecord::Base.connection.exec_query(squery_24h).to_a.first['sum'].to_d
      sum_withdraws_1_month = ActiveRecord::Base.connection.exec_query(squery_1m).to_a.first['sum'].to_d
      [sum_withdraws_24_hours, sum_withdraws_1_month]
    end
  end

  def initialize_defaults
    self.metadata = {} if metadata.blank?
  end

  def account
    member&.get_account(currency)
  end

  def add_error(e)
    if error.blank?
      update!(error: [{ class: e.class.to_s, message: e.message }])
    else
      update!(error: error << { class: e.class.to_s, message: e.message })
    end
  end

  def verify_limits
    limits = WithdrawLimit.for(kyc_level: member.level, group: member.group)

    # If there are no limits in DB or current user withdraw limit
    # has 0.0 for 24 hour and 1 mounth it will skip this checks
    return true if limits.limit_24_hour.zero? && limits.limit_1_month.zero?

    # Withdraw limits in USD and withdraw sum in currency.
    # Convert withdraw sums with price from the currency model.
    sum_24_hours, sum_1_month = Withdraw.sanitize_execute_sum_queries(member_id, id)

    sum_24_hours + (sum * currency.get_price) <= limits.limit_24_hour &&
      sum_1_month + (sum * currency.get_price) <= limits.limit_1_month
  end

  def confirmations
    return 0 if block_number.blank?
    return blockchain.processed_height - block_number if (blockchain.processed_height - block_number) >= 0

    nil
  rescue StandardError => e
    report_exception(e)
    nil
  end

  def completed?
    aasm_state.in?(COMPLETED_STATES.map(&:to_s))
  end

  def as_json_for_event_api
    { tid: tid,
      user: { uid: member.uid, email: member.email },
      uid: member.uid,
      rid: rid,
      currency: currency_id,
      amount: amount.to_s('F'),
      fee: fee.to_s('F'),
      state: aasm_state,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      completed_at: completed_at&.iso8601,
      blockchain_txid: txid }
  end

  def for_notify
    API::V2::Entities::Withdraw.represent(self).as_json
  end

  def trigger_private_event
    ::AMQP::Queue.enqueue_event('private', member&.uid, 'withdraw', for_notify)
  end

  private

  def record_submit_operations!
    transaction do
      # Debit main fiat/crypto Liability account.
      # Credit locked fiat/crypto Liability account.
      Operations::Liability.transfer!(
        amount: sum,
        currency: currency,
        reference: self,
        from_kind: :main,
        to_kind: :locked,
        member_id: member_id
      )
    end
  end

  def record_cancel_operations!
    transaction do
      # Debit locked fiat/crypto Liability account.
      # Credit main fiat/crypto Liability account.
      Operations::Liability.transfer!(
        amount: sum,
        currency: currency,
        reference: self,
        from_kind: :locked,
        to_kind: :main,
        member_id: member_id
      )
    end
  end

  def record_complete_operations!
    transaction do
      # Debit locked fiat/crypto Liability account.
      Operations::Liability.debit!(
        amount: sum,
        currency: currency,
        reference: self,
        kind: :locked,
        member_id: member_id
      )

      # Credit main fiat/crypto Revenue account.
      # NOTE: Credit amount = fee.
      Operations::Revenue.credit!(
        amount: fee,
        currency: currency,
        reference: self,
        member_id: member_id
      )

      # Debit main fiat/crypto Asset account.
      # NOTE: Debit amount = sum - fee.
      Operations::Asset.debit!(
        amount: amount,
        currency: currency,
        reference: self
      )
    end
  end

  def send_coins!
    return if Rails.env.test? || Rails.env.development?

    BelomorClient.new(blockchain_key: blockchain.key)
                 .create_withdrawal(
                   to_address: to_address,
                   amount: amount,
                   currency_id: currency_id,
                   fee: network_fee,
                   owner_id: "user:#{member.uid}",
                   remote_id: id,
                   meta: { note: note }
                 )
  rescue StandardError => e
    report_exception(e)
    err!(e)
  end

  def blockchain_currency
    @blockchain_currency ||= BlockchainCurrency.find_by!(blockchain: blockchain, currency: currency)
  end
end
