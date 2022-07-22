# frozen_string_literal: true

class Account < ApplicationRecord
  AccountError = Class.new(StandardError)
  CannotLockFundsError = Class.new(AccountError)

  self.primary_keys = :currency_id, :member_id

  belongs_to :currency, optional: false
  belongs_to :member, optional: false

  acts_as_eventable prefix: 'account', on: %i[create update]

  has_metrics # inherits: [:member_id, :currency_id]

  ZERO = 0.to_d

  validates :member_id, uniqueness: { scope: :currency_id }
  validates :balance, :locked, numericality: { greater_than_or_equal_to: 0.to_d }

  scope :visible, -> { joins(:currency).merge(Currency.where(visible: true)) }
  scope :ordered, -> { joins(:currency).order(position: :asc) }

  after_commit do
    metrics.write(balance: balance.to_d, locked: locked.to_d, amount: amount.to_d)
  end

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

  def plus_funds!(amount)
    update_columns(attributes_after_plus_funds!(amount))
  end

  def plus_funds(amount)
    with_lock { plus_funds!(amount) }
    self
  end

  def attributes_after_plus_funds!(amount)
    raise AccountError, "Cannot add funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance})." if amount <= ZERO

    { balance: balance + amount }
  end

  def plus_locked_funds!(amount)
    update_columns(attributes_after_plus_locked_funds!(amount))
  end

  def plus_locked_funds(amount)
    with_lock { plus_locked_funds!(amount) }
    self
  end

  def attributes_after_plus_locked_funds!(amount)
    raise AccountError, "Cannot add funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, locked: #{locked})." if amount <= ZERO

    { locked: locked + amount }
  end

  def sub_funds!(amount)
    update_columns(attributes_after_sub_funds!(amount))
  end

  def sub_funds(amount)
    with_lock { sub_funds!(amount) }
    self
  end

  def attributes_after_sub_funds!(amount)
    raise AccountError, "Cannot subtract funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance})." if amount <= ZERO || amount > balance

    { balance: balance - amount }
  end

  def lock_funds!(amount)
    update_columns(attributes_after_lock_funds!(amount))
  end

  def lock_funds(amount)
    with_lock { lock_funds!(amount) }
    self
  end

  def attributes_after_lock_funds!(amount)
    raise CannotLockFundsError, "Cannot lock funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance}, locked: #{locked})." if amount <= ZERO || amount > balance

    { balance: balance - amount, locked: locked + amount }
  end

  def unlock_funds!(amount)
    update_columns(attributes_after_unlock_funds!(amount))
  end

  def unlock_funds(amount)
    with_lock { unlock_funds!(amount) }
    self
  end

  def attributes_after_unlock_funds!(amount)
    raise AccountError, "Cannot unlock funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance} locked: #{locked})." if amount <= ZERO || amount > locked

    { balance: balance + amount, locked: locked - amount }
  end

  def unlock_and_sub_funds!(amount)
    update_columns(attributes_after_unlock_and_sub_funds!(amount))
  end

  def unlock_and_sub_funds(amount)
    with_lock { unlock_and_sub_funds!(amount) }
    self
  end

  def attributes_after_unlock_and_sub_funds!(amount)
    raise AccountError, "Cannot unlock and sub funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, locked: #{locked})." if amount <= ZERO || amount > locked

    { locked: locked - amount }
  end

  def amount
    balance + locked
  end
end
