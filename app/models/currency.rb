# frozen_string_literal: true

class Currency < ApplicationRecord
  # == Constants ============================================================

  OPTIONS_ATTRIBUTES = %i[gas_price].freeze
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

  has_many :blockchain_currencies, dependent: :destroy
  has_many :blockchains, through: :blockchain_currencies
  has_and_belongs_to_many :wallets

  # == Validations ==========================================================
  #
  validate on: :create do
    errors.add(:max, 'Currency limit has been reached') if ENV['MAX_CURRENCIES'].present? && Currency.count >= ENV['MAX_CURRENCIES'].to_i
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
            numericality: { greater_than_or_equal_to: 0 }

  # == Scopes ===============================================================

  scope :visible, -> { where(visible: true) }
  scope :deposit_enabled, -> { where(deposit_enabled: true) }
  scope :withdrawal_enabled, -> { where(withdrawal_enabled: true) }
  scope :ordered, -> { order(position: :asc) }
  scope :coins, -> { where(type: :coin) }
  scope :fiats, -> { where(type: :fiat) }

  # == Callbacks ============================================================

  after_initialize :initialize_defaults
  after_create do
    insert_position(self)
  end

  before_validation { self.code = code.downcase }
  before_validation { self.deposit_fee = 0 unless fiat? }
  before_validation(on: :create) { self.position = Currency.count + 1 if position.blank? }

  before_update { update_position(self) if position_changed? }

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

  types.each { |t| define_method("#{t}?") { type == t.to_s } }

  def wipe_cache
    Rails.cache.delete_matched('currencies*')
  end

  def initialize_defaults
    self.options = {} if options.blank?
  end

  # Allows to dynamically check value of id/code:
  #
  #   id.btc? # true if code equals to "btc".
  #   code.eth? # true if code equals to "eth".
  def id
    super&.inquiry
  end

  def icon_id
    id.to_s.downcase.split(ID_SEPARATOR).first.presence
  end

  def get_price
    if price.blank? || price.zero?
      raise "Price for currency #{id} is unknown"
    else
      price
    end
  end

  def dependent_markets
    Market.where('base_unit = ? OR quote_unit = ?', id, id)
  end
end
