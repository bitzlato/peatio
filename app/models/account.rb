# frozen_string_literal: true

class Account < ApplicationRecord
  class UIDGenerator
    def self.generate(prefix)
      loop do
        uid = [prefix.upcase, SecureRandom.hex(5).upcase].join
        return uid if Account.where(uid: uid).empty?
      end
    end
  end
  CATEGORIES = %w[spot main p2p].freeze

  raise 'Categories must have unique first char' unless CATEGORIES.map(&:first).uniq.count == CATEGORIES.count

  AccountError = Class.new(StandardError)

  belongs_to :currency, optional: false
  belongs_to :member, optional: false
  has_one :blockchain, through: :currency
  has_many :withdraws, dependent: :restrict_with_exception
  has_many :deposits, dependent: :restrict_with_exception

  acts_as_eventable prefix: 'account', on: %i[create update]

  ZERO = 0.to_d

  before_validation on: :create do
    self.category ||= 'spot'
  end
  before_validation :assign_uid, on: :create

  validates :member_id, uniqueness: { scope: :currency_id }
  validates :balance, :locked, numericality: { greater_than_or_equal_to: 0.to_d }
  validates :category, inclusion: { in: CATEGORIES }
  validates :uid, presence: true, uniqueness: true

  scope :visible, -> { joins(:currency).merge(Currency.where(visible: true)) }
  scope :ordered, -> { joins(:currency).order(position: :asc) }

  delegate :enable_invoice?, :enable_invoice, to: :blockchain

  before_update do
    # Мы пока не поддерживаем другие виды аккаунтов
    raise "Unknown account type #{category}" unless category == 'spot'
  end

  def as_json_for_event_api
    {
      member_id: member_id,
      currency_id: currency_id,
      balance: balance,
      locked: locked,
      category: category,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
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

  def assign_uid
    return if uid.present?

    self.uid = UIDGenerator.generate('A' + category.first.upcase)
  end
end
