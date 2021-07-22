# encoding: UTF-8
# frozen_string_literal: true

class Wallet < ApplicationRecord
  extend Enumerize

  serialize :balance, JSON unless Rails.configuration.database_support_json

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

  SETTING_ATTRIBUTES = %i[uri secret client_uid save_beneficiary beneficiary_prefix enable_invoice].freeze

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

  belongs_to :blockchain, foreign_key: :blockchain_key, primary_key: :key
  has_and_belongs_to_many :currencies
  has_many :currency_wallets

  validates :name,    presence: true, uniqueness: true
  validates :address, presence: true

  validates :status,  inclusion: { in: %w[active disabled] }

  validates :gateway, inclusion: { in: ->(_){ Wallet.gateways.map(&:to_s) } }

  validates :max_balance, numericality: { greater_than_or_equal_to: 0 }

  scope :active,   -> { where(status: :active) }
  scope :deposit,  -> { where(kind: kinds(deposit: true, values: true)) }
  scope :fee,      -> { where(kind: kinds(fee: true, values: true)) }
  scope :withdraw, -> { where(kind: kinds(withdraw: true, values: true)) }
  scope :with_currency, ->(currency) { joins(:currencies).where(currencies: { id: currency }) }
  scope :with_withdraw_currency, ->(currency) { with_currency(currency).joins(:currency_wallets).where(currencies_wallets: { enable_withdraw: true }) }
  scope :with_deposit_currency, ->(currency) { with_currency(currency).joins(:currency_wallets).where(currencies_wallets: { enable_deposit: true }) }
  scope :ordered, -> { order(kind: :asc) }

  before_validation(on: :create) do
    if address.blank? && settings[:uri].present? && currencies.present?
      begin
        result = generate_settings
      rescue StandardError => e
        Rails.logger.info { "Cannot generate wallet address and secret error: #{e.message}" }
        result = { address: 'changeme', secret: 'changeme' }
      ensure
        if result.present?
          self.address = result[:address]
          self.secret = result[:secret]
        end
      end
    end
  end

  before_validation do
    next unless address? && blockchain.try(:blockchain_api).try(:supports_cash_addr_format?)
    self.address = CashAddr::Converter.to_cash_address(address)
  end

  class << self
    def gateways
      Peatio::Wallet.registry.adapters.keys
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

    def deposit_wallet(currency_id)
      Wallet.active.deposit.with_deposit_currency(currency_id).take
    end

    def withdraw_wallet(currency_id)
      Wallet.active.withdraw.with_withdraw_currency(currency_id).take
    end
  end

  def current_balance(currency = nil)
    if currency.present?
      WalletService.new(self).load_balance!(currency)
    else
      currencies.each_with_object({}) do |c, balances|
        balances[c.id] = WalletService.new(self).load_balance!(c)
      rescue StandardError => e
        report_exception(e)
        balances[c.id] = NOT_AVAILABLE
      end
    end
  rescue StandardError => e
    report_exception(e)
    NOT_AVAILABLE
  end

  def to_wallet_api_settings
    settings.compact.deep_symbolize_keys.merge(address: address)
  end

  def wallet_url
    blockchain.explorer_address.gsub('#{address}', address) if blockchain
  end

  def service
    ::WalletService.new(self)
  end

  def generate_settings
    service.create_address!('peatio', {})
  end
end

# == Schema Information
# Schema version: 20201125134745
#
# Table name: wallets
#
#  id                 :integer          not null, primary key
#  blockchain_key     :string(32)
#  name               :string(64)
#  address            :string(255)      not null
#  kind               :integer          not null
#  gateway            :string(20)       default(""), not null
#  settings_encrypted :string(1024)
#  balance            :json
#  max_balance        :decimal(32, 16)  default(0.0), not null
#  status             :string(32)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_wallets_on_kind                             (kind)
#  index_wallets_on_kind_and_currency_id_and_status  (kind,status)
#  index_wallets_on_status                           (status)
#
