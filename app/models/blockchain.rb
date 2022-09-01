# frozen_string_literal: true

# Rename to Gateway
#
class Blockchain < ApplicationRecord
  self.ignored_columns = ['server_encrypted']

  include GatewayConcern
  include BlockchainExploring

  has_many :wallets
  has_many :whitelisted_smart_contracts
  has_many :withdraws
  has_many :blockchain_currencies, dependent: :destroy
  has_many :currencies, through: :blockchain_currencies
  has_many :payment_addresses
  has_many :transactions, dependent: :restrict_with_exception
  has_many :deposits, dependent: :restrict_with_exception
  has_many :gas_refuels
  has_many :block_numbers

  validates :key, :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active disabled] }
  validates :height,
            :min_confirmations,
            numericality: { greater_than_or_equal_to: 1, only_integer: true }
  before_create { self.key = key.strip.downcase }

  scope :active, -> { where(status: :active) }

  def native_currency
    blockchain_currencies.find_by(parent_id: nil)&.currency || raise("No native currency for blockchain id #{id}")
  end

  # Support legacy API for tower
  #
  def status
    super&.inquiry
  end

  def client_options
    super.with_indifferent_access
  end

  def hot_wallet
    wallets.active.hot.take
  end

  def withdraw_wallet_for_currency(currency)
    wallets
      .active
      .hot
      .with_withdraw_currency(currency)
      .take
  end

  def wallets_addresses
    Set.new(wallets.where.not(address: nil).pluck(:address).map { |a| normalize_address a }).freeze
  end

  def deposit_addresses
    Set.new(payment_addresses.where.not(address: nil).pluck(:address).map { |a| normalize_address a }).freeze
  end

  delegate :active?, to: :status

  # The latest block which blockchain worker has processed
  def processed_height
    height + min_confirmations
  end
end
