# frozen_string_literal: true

class Currency < ApplicationRecord
  # == Constants ============================================================

  # TODO: remove erc20 contract_address
  OPTIONS_ATTRIBUTES = %i[erc20_contract_address gas_limit gas_price].freeze
  TOP_POSITION = 1
  ID_SEPARATOR = '-'

  # == Attributes ===========================================================

  attr_readonly :id,
                :type

  # Code is aliased to id because it's more user-friendly primary key.
  # It's preferred to use code where this attributes are equal.
  alias_attribute :code, :id
  alias_attribute :priority, :position

  # == Extensions ===========================================================

  has_many :withdraws
  has_many :deposits
  has_many :transactions

  serialize :options, JSON unless Rails.configuration.database_support_json

  include Helpers::ReorderPosition

  OPTIONS_ATTRIBUTES.each do |attribute|
    define_method attribute do
      options[attribute.to_s]
    end

    define_method "#{attribute}=".to_sym do |value|
      self.options = options.merge(attribute.to_s => value)
    end
  end

  # == Relationships ========================================================

  has_one :blockchain_currency, dependent: :destroy
  has_one :blockchain, through: :blockchain_currency
  has_and_belongs_to_many :wallets

  # == Validations ==========================================================
  #
  before_validation on: :create do
    # Это устанавливате сятолько для того чтобы проходили специфичные тесты которые надо подправить
    # чтобы онги сами усатанвилвали base_factor
    self.base_factor ||= 2
  end

  # Support for tower
  before_update if: :erc20_contract_address do
    self.contract_address ||= erc20_contract_address
  end

  validate on: :create do
    errors.add(:max, 'Currency limit has been reached') if ENV['MAX_CURRENCIES'].present? && Currency.count >= ENV['MAX_CURRENCIES'].to_i
  end

  validates :code, presence: true, uniqueness: { case_sensitive: false }

  validates :position,
            presence: true,
            numericality: { greater_than_or_equal_to: TOP_POSITION, only_integer: true }

  validates :type, inclusion: { in: ->(_) { Currency.types.map(&:to_s) } }
  validates :options, length: { maximum: 1000 }
  validates :base_factor, presence: true

  validates :deposit_fee,
            :min_deposit_amount,
            :min_collection_amount,
            :withdraw_fee,
            :min_withdraw_amount,
            :withdraw_limit_24h,
            :withdraw_limit_72h,
            numericality: { greater_than_or_equal_to: 0 }

  # == Scopes ===============================================================

  scope :visible, -> { where(visible: true) }
  scope :deposit_enabled, -> { where(deposit_enabled: true) }
  scope :withdrawal_enabled, -> { where(withdrawal_enabled: true) }
  scope :ordered, -> { order(position: :asc) }
  scope :coins, -> { where(type: :coin) }
  scope :fiats, -> { where(type: :fiat) }
  # This scope select all coins without parent_id, which means that they are not tokens
  scope :coins_without_tokens, -> { coins.joins(:blockchain_currency).where(blockchain_currencies: { parent_id: nil }) }
  scope :tokens, -> { coins.joins(:blockchain_currency).where.not(blockchain_currencies: { parent_id: nil }) }

  # == Callbacks ============================================================

  after_initialize :initialize_defaults
  after_create do
    insert_position(self)
  end

  before_validation { self.code = code.downcase }
  before_validation { self.deposit_fee = 0 unless fiat? }
  before_validation(on: :create) { self.position = Currency.count + 1 if position.blank? }

  before_validation do
    self.erc20_contract_address = erc20_contract_address.try(:downcase) if erc20_contract_address.present?
  end

  before_update { update_position(self) if position_changed? }

  delegate :enable_invoice?, to: :blockchain
  delegate :to_money_from_decimal, :to_money_from_units, to: :money_currency

  after_commit :wipe_cache

  # == Class Methods ========================================================

  # NOTE: type column reserved for STI
  self.inheritance_column = nil

  class << self
    def codes(options = {})
      pluck(:id).yield_self do |downcase_codes|
        if options.fetch(:bothcase, false)
          downcase_codes + downcase_codes.map(&:upcase)
        elsif options.fetch(:upcase, false)
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
  delegate :key, to: :blockchain, prefix: true

  types.each { |t| define_method("#{t}?") { type == t.to_s } }

  def blockchain_key=(key)
    self.blockchain = Blockchain.find_by_key!(key)
  end

  def wipe_cache
    Rails.cache.delete_matched('currencies*')
  end

  def initialize_defaults
    self.options = {} if options.blank?
  end

  # quick fix specs
  def money_code
    return 'fake' if code.start_with? 'fake'
  end

  def money_currency
    @money_currency ||= Money::Currency.find!(id)
  end

  # Allows to dynamically check value of id/code:
  #
  #   id.btc? # true if code equals to "btc".
  #   code.eth? # true if code equals to "eth".
  def id
    super&.inquiry
  end

  def token_name
    return unless token?

    id.to_s.upcase.split(ID_SEPARATOR).first.presence
  end

  def icon_id
    id.to_s.downcase.split(ID_SEPARATOR).first.presence
  end

  # subunit (or fractional monetary unit) - a monetary unit
  # that is valued at a fraction (usually one hundredth)
  # of the basic monetary unit
  def subunits=(n)
    self.base_factor = 10**n
  end

  def subunits
    Math.log(base_factor, 10).round
  end

  # This method defines that token currency need to have parent_id and coin type
  # We use parent_id for token type to inherit some useful info such as blockchain_key from parent currency
  # For coin currency enough to have only coin type
  def token?
    blockchain_currency.parent_id.present? && coin?
  end

  def subunit_to_unit
    base_factor
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
    opt.deep_symbolize_keys.merge(id: id,
                                  base_factor: base_factor,
                                  min_collection_amount: min_collection_amount,
                                  options: opt)
  end

  def min_deposit_amount_money
    money_currency.to_money_from_decimal min_deposit_amount
  end

  def min_withdraw_amount_money
    money_currency.to_money_from_decimal min_withdraw_amount
  end

  def dependent_markets
    Market.where('base_unit = ? OR quote_unit = ?', id, id)
  end
end
