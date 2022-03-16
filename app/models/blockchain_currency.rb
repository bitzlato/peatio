# frozen_string_literal: true

class BlockchainCurrency < ApplicationRecord
  belongs_to :currency
  belongs_to :blockchain
  belongs_to :parent, class_name: 'BlockchainCurrency'

  before_validation on: :create do
    self.base_factor ||= 18 if Rails.env.test?
  end

  validate if: :parent_id do
    errors.add :parent_id, 'wrong fiat/crypto nesting' unless currency.fiat? == parent.currency.fiat?
    errors.add :parent_id, 'nesting currency must be token' unless token?
    errors.add :parent_id, 'wrong parent blockchain currency' if parent.parent_id.present?
  end
  validates :base_factor, presence: true
  validates :min_deposit_amount, :withdraw_fee, numericality: { greater_than_or_equal_to: 0 }

  scope :tokens, -> { joins(:currency).merge(Currency.coins).where.not(parent_id: nil) }

  after_create do
    link_wallets
  end
  before_validation(if: :token?) { self.blockchain ||= parent.blockchain }

  delegate :to_money_from_decimal, :to_money_from_units, to: :money_currency

  def link_wallets
    return if parent_id.nil?

    # Iterate through active deposit/withdraw wallets
    Wallet.active.where.not(kind: :fee).with_currency(parent.currency_id).each do |wallet|
      # Link parent currency with wallet
      CurrencyWallet.create(currency_id: currency_id, wallet_id: wallet.id)
    end
  end

  def token?
    parent_id.present? && currency.coin?
  end

  def money_currency
    @money_currency ||= Money::Currency.find!(id)
  end

  def min_deposit_amount_money
    money_currency.to_money_from_decimal(min_deposit_amount)
  end

  def min_withdraw_amount_money
    money_currency.to_money_from_decimal(currency.min_withdraw_amount)
  end

  def subunit_to_unit
    base_factor
  end

  # subunit (or fractional monetary unit) - a monetary unit
  # that is valued at a fraction (usually one hundredth)
  # of the basic monetary unit
  def subunits=(value)
    self.base_factor = 10**value
  end

  def subunits
    Math.log(base_factor, 10).round
  end

  def parent_currency
    parent ? parent.currency : currency
  end
end
