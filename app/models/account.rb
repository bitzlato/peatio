# frozen_string_literal: true

class Account < ApplicationRecord
  self.table_name = :openbill_account
  include AccountTransactions

  self.primary_keys = :currency_id, :member_id

  belongs_to :currency, optional: false
  belongs_to :member, optional: false
  has_one :blockchain, through: :currency

  acts_as_eventable prefix: 'account', on: %i[create update]

  ZERO = 0.to_d

  validates :member_id, uniqueness: { scope: :currency_id }
  validates :balance, :locked, numericality: { greater_than_or_equal_to: 0.to_d }

  scope :visible, -> { joins(:currency).merge(Currency.where(visible: true)) }
  scope :ordered, -> { joins(:currency).order(position: :asc) }

  delegate :enable_invoice?, :enable_invoice, to: :blockchain

  def as_json_for_event_api
    {
      member_id: member_id,
      currency_id: currency_id,
      balance: balance,
      locked: locked,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  def deposits
    Deposit.where(member_id: member_id, currency_id: currency_id)
  end

  def withdraws
    Withdraw.where(member_id: member_id, currency_id: currency_id)
  end

  def payment_address
    member.payment_address blockchain
  end

  def amount
    balance + locked
  end
end
