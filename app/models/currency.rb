# encoding: UTF-8
# frozen_string_literal: true

class Currency < ApplicationRecord

  # == Constants ============================================================

  OPTIONS_ATTRIBUTES = %i[erc20_contract_address gas_limit gas_price].freeze
  TOP_POSITION = 1

  # == Attributes ===========================================================

  attr_readonly :id,
                :type

  # Code is aliased to id because it's more user-friendly primary key.
  # It's preferred to use code where this attributes are equal.
  alias_attribute :code, :id

  # == Extensions ===========================================================


  has_many :withdraws

  serialize :options, JSON unless Rails.configuration.database_support_json

  include Helpers::ReorderPosition

  OPTIONS_ATTRIBUTES.each do |attribute|
    define_method attribute do
      self.options[attribute.to_s]
    end

    define_method "#{attribute}=".to_sym do |value|
      self.options = options.merge(attribute.to_s => value)
    end
  end

  # == Relationships ========================================================

  belongs_to :blockchain, required: true
  has_and_belongs_to_many :wallets

  belongs_to :parent, class_name: 'Currency'

  # == Validations ==========================================================

  validate on: :create do
    if ENV['MAX_CURRENCIES'].present? && Currency.count >= ENV['MAX_CURRENCIES'].to_i
      errors.add(:max, 'Currency limit has been reached')
    end
  end

  validates :code, presence: true, uniqueness: { case_sensitive: false }

  validates :position,
            presence: true,
            numericality: { greater_than_or_equal_to: TOP_POSITION, only_integer: true }

  validates :type, inclusion: { in: ->(_) { Currency.types.map(&:to_s) } }
  validates :options, length: { maximum: 1000 }

  validates :deposit_fee,
            :min_deposit_amount,
            :min_collection_amount,
            :withdraw_fee,
            :min_withdraw_amount,
            :withdraw_limit_24h,
            :withdraw_limit_72h,
            :precision,
            numericality: { greater_than_or_equal_to: 0 }

  # == Scopes ===============================================================

  scope :visible, -> { where(visible: true) }
  scope :deposit_enabled, -> { where(deposit_enabled: true) }
  scope :withdrawal_enabled, -> { where(withdrawal_enabled: true) }
  scope :ordered, -> { order(position: :asc) }
  scope :coins, -> { where(type: :coin) }
  scope :fiats, -> { where(type: :fiat) }
  # This scope select all coins without parent_id, which means that they are not tokens
  scope :coins_without_tokens, -> { coins.where(parent_id: nil) }

  # == Callbacks ============================================================

  after_initialize :initialize_defaults
  after_create do
    link_wallets
    insert_position(self)
  end

  before_validation { self.code = code.downcase }
  before_validation { self.deposit_fee = 0 unless fiat? }
  before_validation(if: :token?) { self.blockchain ||= parent.blockchain }
  before_validation(on: :create) { self.position = Currency.count + 1 unless position.present? }

  before_validation do
    self.erc20_contract_address = erc20_contract_address.try(:downcase) if erc20_contract_address.present?
  end

  validate if: :parent_id do
    errors.add :parent_id, 'wrong fiat/crypto nesting' unless fiat? == parent.fiat?
    errors.add :parent_id, 'nesting currency must be token' unless token?
    errors.add :parent_id, 'wrong parent currency' if parent.parent_id.present?
  end

  before_update { update_position(self) if position_changed? }
  delegate :key, to: :blockchain, prefix: true

  after_commit :wipe_cache

  # == Class Methods ========================================================

  # NOTE: type column reserved for STI
  self.inheritance_column = nil

  class << self
    def codes(options = {})
      pluck(:id).yield_self do |downcase_codes|
        case
        when options.fetch(:bothcase, false)
          downcase_codes + downcase_codes.map(&:upcase)
        when options.fetch(:upcase, false)
          downcase_codes.map(&:upcase)
        else
          downcase_codes
        end
      end
    end

    def types
      %i[fiat coin].freeze
    end
  end

  # == Instance Methods =====================================================

  delegate :explorer_transaction, :explorer_address, to: :blockchain

  types.each { |t| define_method("#{t}?") { type == t.to_s } }

  def wipe_cache
    Rails.cache.delete_matched("currencies*")
  end

  def initialize_defaults
    self.options = {} if options.blank?
  end

  def money_currency
    @money_currency ||= Money::Currency.find! code
  end

  def link_wallets
    if parent_id.present?
      # Iterate through active deposit/withdraw wallets
      Wallet.active.where.not(kind: :fee).with_currency(parent_id).each do |wallet|
        # Link parent currency with wallet
        CurrencyWallet.create(currency_id: id, wallet_id: wallet.id)
      end
    end
  end

  # Allows to dynamically check value of id/code:
  #
  #   id.btc? # true if code equals to "btc".
  #   code.eth? # true if code equals to "eth".
  def id
    super&.inquiry
  end

  # subunit (or fractional monetary unit) - a monetary unit
  # that is valued at a fraction (usually one hundredth)
  # of the basic monetary unit
  def subunits=(n)
    self.base_factor = 10 ** n
  end

  # This method defines that token currency need to have parent_id and coin type
  # We use parent_id for token type to inherit some useful info such as blockchain_key from parent currency
  # For coin currency enough to have only coin type
  def token?
    parent_id.present? && coin?
  end

  def get_price
    if price.blank? || price.zero?
      raise "Price for currency #{id} is unknown"
    else
      price
    end
  end

  def to_blockchain_api_settings
    # We pass options are available as top-level hash keys and via options for
    # compatibility with Wallet#to_wallet_api_settings.
    opt = options.compact.deep_symbolize_keys
    opt.deep_symbolize_keys.merge(id:                    id,
                                  base_factor:           base_factor,
                                  min_collection_amount: min_collection_amount,
                                  options:               opt)
  end

  def dependent_markets
    Market.where('base_unit = ? OR quote_unit = ?', id, id)
  end

  def subunits
    Math.log(base_factor, 10).round
  end
end
