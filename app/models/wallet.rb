# encoding: UTF-8
# frozen_string_literal: true

class Wallet < ApplicationRecord
  extend Enumerize

  serialize :balance, JSON unless Rails.configuration.database_support_json
  serialize :plain_settings, JSON unless Rails.configuration.database_support_json

  include Vault::EncryptedModel

  vault_lazy_decrypt!

  # We use this attribute values rules for wallet kinds:
  # 1** - for deposit wallets.
  # 2** - for fee wallets.
  # 3** - for withdraw wallets (sorted by security hot < warm < cold).
  #
  # We use standalone wallet for deposits and withdraws for P2P
  #
  ENUMERIZED_KINDS = { deposit: 100, fee: 200, hot: 310, warm: 320, cold: 330, standalone: 400 }.freeze
  enumerize :kind, in: ENUMERIZED_KINDS, scope: true

  SETTING_ATTRIBUTES = %i[uri secret client_uid save_beneficiary beneficiary_prefix].freeze
  STATES = %w[active disabled retired].freeze
  # active - system use active wallets for all user transactions transfers.
  # retired - system use retired wallet only to accept deposits.
  # disabled - system don't use disabled wallets in user transactions transfers.

  SETTING_ATTRIBUTES.each do |attribute|
    define_method attribute do
      self.settings[attribute.to_s]
    end

    define_method "#{attribute}=".to_sym do |value|
      self.settings = self.settings.merge(attribute.to_s => value)
    end
  end

  NOT_AVAILABLE = 'N/A'.freeze

  vault_attribute :settings, serialize: :json, default: {}

  belongs_to :blockchain
  has_and_belongs_to_many :currencies
  has_many :currency_wallets

  validates :name,    presence: true, uniqueness: true
  validates :address, presence: true
  validate :gateway_wallet_kind_support

  validates :status,  inclusion: { in: STATES }

  validates :max_balance, numericality: { greater_than_or_equal_to: 0 }

  scope :active,   -> { where(status: :active) }
  scope :active_retired, -> { where(status: %w[active retired]) }
  scope :deposit,  -> { where(kind: kinds(deposit: true, values: true)) }
  scope :fee,      -> { where(kind: kinds(fee: true, values: true)) }
  scope :withdraw, -> { where(kind: kinds(withdraw: true, values: true)) }
  scope :with_currency, ->(currency) { joins(:currencies).where(currencies: { id: currency }) }
  scope :with_withdraw_currency, ->(currency) { with_currency(currency).joins(:currency_wallets).where(currencies_wallets: { enable_withdraw: true }) }
  scope :with_deposit_currency, ->(currency) { with_currency(currency).joins(:currency_wallets).where(currencies_wallets: { enable_deposit: true }) }
  scope :ordered, -> { order(kind: :asc) }

  delegate :key, to: :blockchain, prefix: true
  delegate :create_address!, :gateway, to: :blockchain

  before_validation :generate_settings, on: :create
  before_validation do
    next unless address? && blockchain.try(:blockchain_api).try(:supports_cash_addr_format?)
    self.address = CashAddr::Converter.to_cash_address(address)
  end

  class << self
    def blockchain_key_eq(key)
      joins(:blockchain).where(blockchains: { key: key })
    end

    def self.ransackable_attributes(_auth_object = nil)
      super + %w(blockchain_key_eq)
    end

    def kinds(options={})
      ENUMERIZED_KINDS
        .yield_self do |kinds|
          case
          when options.fetch(:deposit, false)
            kinds.select { |_k, v| [1,4].include? v / 100 }
          when options.fetch(:fee, false)
            kinds.select { |_k, v| v / 100 == 2 }
          when options.fetch(:withdraw, false)
            kinds.select { |_k, v| [3,4].include? v / 100 }
          else
            kinds
          end
        end
        .yield_self do |kinds|
          case
          when options.fetch(:keys, false)
            kinds.keys
          when options.fetch(:values, false)
            kinds.values
          else
            kinds
          end
        end
    end

    def deposit_wallets(currency_id)
      Wallet.active.deposit.with_deposit_currency(currency_id)
    end

    def deposit_wallet(currency_id)
      deposit_wallets(currency_id).active_retired.take
    end

    def active_deposit_wallet(currency_id)
      deposit_wallets(currency_id).take
    end

    def withdraw_wallet(currency_id)
      Wallet.active.withdraw.with_withdraw_currency(currency_id).take
    end

    def uniq(array)
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        array.select("DISTINCT ON (wallets.id) wallets.*")
      else
        array.distinct
      end
    end
  end

  def blockchain_key=(key)
    return self.blockchain = nil if key.nil?
    self.blockchain = Blockchain.find_by(key: key) || raise("No blockchain with key #{key}")
  end

  def current_balance(currency = nil)
    if currency.present?
      begin
        currency = currency.money_currency unless currency.is_a? Money::Currency
        gateway.load_balance(uri, address, currency) || NOT_AVAILABLE
      rescue Peatio::Wallet::ClientError
        NOT_AVAILABLE
      end
    else
      currencies.each_with_object({}) do |c, balances|
        balances[c.id] = current_balance(c)
      end
    end
  end

  def gateway_wallet_kind_support
    errors.add(:gateway, "'#{gateway.name}' can't be used as a '#{kind}' wallet") unless gateway.support_wallet_kind?(kind)
  end

  def to_wallet_api_settings
    settings.compact.deep_symbolize_keys.merge(address: address)
  end

  # Rename to exlporer_url
  def wallet_url
    blockchain.explorer_address.gsub('#{address}', address) if blockchain
  end

  def native_currency
    currencies.find { |c| c.parent_id.nil? } || raise("No native currency for wallet id #{id}")
  end

  def generate_settings
    return unless address.blank? && settings[:uri].present? && currencies.present?
    result = create_address!.reverse_merge details: {}
  rescue StandardError => e
    Rails.logger.info { "Cannot generate wallet address and secret error: #{e.message}" }
    result = { address: 'changeme', secret: 'changeme' }
  ensure
    if result.present?
      self.address = result.delete(:address)
      self.settings = self.settings.merge(result)
    end
  end
end
