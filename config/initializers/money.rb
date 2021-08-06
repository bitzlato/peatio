# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

require 'ws/ethereum/helpers'

# rubocop:disable Style/ClassAndModuleChildren
class Money::Currency
  include WS::Ethereum::Helpers
  attr_reader :contract_address, :parent_currency, :precesion, :base_factor_subunits

  class << self
    def find!(code)
      find(code) || raise("No #{code} Money::Currency found!")
    end
  end

  def initialize_data!
    # Inherited attributes
    #
    @alternate_symbols     = data[:alternate_symbols]
    @decimal_mark          = data[:decimal_mark]
    @disambiguate_symbol   = data[:disambiguate_symbol]
    @html_entity           = data[:html_entity]
    @iso_code              = data[:iso_code]
    @iso_numeric           = data[:iso_numeric]
    @name                  = data[:name]
    @priority              = data[:priority]
    @smallest_denomination = data[:smallest_denomination]
    @subunit               = data[:subunit]
    @subunit_to_unit       = data[:subunit_to_unit]
    @symbol                = data[:symbol]
    @symbol_first          = data[:symbol_first]
    @thousands_separator   = data[:thousands_separator]
    @format                = data[:format]

    # Crypto currency attributes
    #
    @contract_address = data[:contract_address]
    @parent_currency = data[:parent_currency]
    @blockchain_key = data[:blockchain_key]
    @base_factor_subunits = data[:base_factor_subunits]
    @precesion = data[:precesion] || @base_factor_subunits

    if blockchain_key.present?
      raise "No base_factor_subunits or currency '#{@id}'" unless @base_factor_subunits
      raise "No precesion or currency '#{@id}'" unless @precesion

      @base_factor = 10 ** base_factor_subunits
      @subunit_to_unit ||= @base_factor
    end
  end

  def blockchain
    return if blockchain_key.nil?
    @blockchain ||= Blockhain.find_by_key(blockchain_key) ||
      raise("No blockchain #{blockchain_key} is found")
  end

  def parent_currency
    return if @parent_currency.nil?
    Money::Currency.find! @parent_currency
  end

  def blockchain_key
    raise "You must not use blockchain_key (#{@blockchain_key})) in nested currency (#{@id}). It inherits from parent currency" if @blockchain_key && @parent_currency.present?
    @blockchain_key || parent_currency.blockchain_key
  end

  def to_money(value)
    value.to_money self
  end

  def base_factor
    @base_factor || raise("base_factor is nil for currency #{to_s}")
  end

  def convert_to_base_unit(value)
    x = value.to_d * base_factor
    unless (x % 1).zero?
      raise "Failed to convert currency (#{to_s}) value to base (smallest) unit because it exceeds the maximum precision: " \
        "#{value.to_d} - #{x.to_d} must be equal to zero."
    end
    x.to_i
  end

  def zero_money
    0.to_money self
  end

  def crypto?
    # TODO rename blockchain_key to gateway
    blockchain_key.present?
  end

  def token?
    contract_address.present?
  end

  private

  def data
     self.class.table[@id] || raise("No #{@id} currency defined in table")
  end
end
# rubocop:enable Style/ClassAndModuleChildren

Money.locale_backend = :i18n
Money.default_currency = :RUB
Money.default_bank = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN

CURRENCIES_PATH = Rails.root.join './config/money_currencies.yml'

currencies = Psych
  .load(File.read(CURRENCIES_PATH))
  .each_with_object({}) { |values, hash| hash[values.first.to_sym] = values.second.symbolize_keys.reverse_merge(iso_code: values.first.upcase) }
  .each_with_index { |data, index| data.second.reverse_merge! priority: index }

Money::Currency::Loader.load! currencies

class Money
  def base_units
    currency.convert_to_base_unit to_d
  end
end

Money::Currency.all
