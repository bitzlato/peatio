# frozen_string_literal: true

class Account < ApplicationRecord
  AccountError = Class.new(StandardError)

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

  def orders
    member.orders.with_currency(currency_id)
  end

  def base_orders
    member.orders.where(base_unit: :currency_id)
  end

  def quote_orders
    member.orders.where(quote_unit: :currency_id)
  end

  def calculated_locked
    deposits.where(is_locked: true).sum(:amount) +
      withdraws.where(is_locked: true).sum(:amount) +
      locked_in_orders
  end

  def locked_in_orders
    OrderAsk.active.where(member_id: id).where(quote_unit: currency_id).sum(:locked) +
      OrderBid.active.where(member_id: id).where(base_unit: currency_id).sum(:locked)
  end

  def verify_locks
    account.locked == calculated_locked
  end

  def verify_locks!
    Bugsnag.notify 'Отличается сумма заблокированная на счёте и расчётная' do |b|
      b.secerity = :warn
      b.meta_data = {
        account_id: id,
        locked: locked,
        calculated_locked: calculated_locked,
        locked_in_orders: locked_in_orders
      }
    end
    true # Пока всегда отдаём true
  end

  def payment_address
    member.payment_address blockchain
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
    raise AccountError, "Cannot lock funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance}, locked: #{locked})." if amount <= ZERO || amount > balance

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
