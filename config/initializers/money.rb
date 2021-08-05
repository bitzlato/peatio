# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

Money.locale_backend = :i18n
Money.default_currency = :RUB

MoneyRails.configure do |config|
  config.default_bank = nil
  config.amount_column = { postfix: '_cents', type: :integer, null: false, limit: 8, default: 0, present: true }

  # default
  config.rounding_mode = BigDecimal::ROUND_HALF_EVEN
  config.default_format = {
    no_cents_if_whole: true,
    translate: true,
    drop_trailing_zeros: true
  }
end

class Money
  def base_units
    currency.convert_to_base_unit to_d
  end
end

require 'ws/ethereum/helpers'
# rubocop:disable Style/ClassAndModuleChildren
class Money::Currency
  include WS::Ethereum::Helpers

  def convert_to_base_unit(value)
    x = value.to_d * base_factor
    unless (x % 1).zero?
      raise Peatio::Wallet::ClientError,
        "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " \
        "#{value.to_d} - #{x.to_d} must be equal to zero."
    end
    x.to_i
  end

  def zero_money
    0.to_money self
  end

  def crypto?
    self.class.table[@id][:is_crypto]
  end

  def contract_address
    self.class.table[@id][:contract_address]
  end

  def native_currency
    nc = self.class.table[@id][:native_currency]
    return if nc.nil?
    @native_currency ||= Money::Currency.find nc
  end

  def base_factor
    self.class.table[@id][:base_factor]
  end

  def token?
    contract_address.present?
  end
end
# rubocop:enable Style/ClassAndModuleChildren
#
# Загружаем только нужные
CURRENCIES_PATH = Rails.root.join './config/money_currencies.yml'
Psych.load(File.read(CURRENCIES_PATH)).each { |_key, cur| Money::Currency.register cur.symbolize_keys }
