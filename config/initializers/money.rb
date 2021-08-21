# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>
# rubocop:disable Style/ClassAndModuleChildren
class Money
  def base_units
    currency.convert_to_base_unit to_d
  end

  class Currency
    module Loader
      def load!
        @currencies = []
      end
    end

    include NumericHelpers

    class << self
      def find!(code)
        find(code) || raise("No #{code} Money::Currency found!")
      end
    end

    attr_reader :currency_record
    delegate :priority, :subunit_to_unit, :contract_address, :precision, :name, :subunit, :base_factor,
      :crypto?, :token?, :blockchain, to: :currency_record

    def initialize_data!
      # Typical initialization
      # data = self.class.table[@id] || raise("No #{@id} currency defined in table")
      @currency_record = ::Currency.find(id) || raise(UnknownCurrency, id)

      #@base_factor_subunits = data[:base_factor_subunits]

      #raise "You can't set base_factor_subunits and subunit_to_unit in same time #{data}" if @base_factor_subunits && @subunit_to_unit

      ## base_factor_subunits - zero's count (for example: 2)
      ## subunit_to_unit - amount of subunits (cents) in unit (dollar) (for example: 100)
      ## base_factor is alias of subunit_to_unit

      #if @base_factor_subunits.present?
        #@subunit_to_unit = 10 ** @base_factor_subunits
      #elsif @subunit_to_unit.present?
        #@base_factor_subunits = Math.log(@subunit_to_unit, 10).round
      #else
        #raise "No subunit_to_unit or base_factor_subunits for currency '#{@id}'"
      #end

      #raise "No contract_address for #{@id}" if @parent_currency.present? && !@contract_address

      #@precision = data[:precision] || @base_factor_subunits
    end

   # TODO rename from_units_to_money
    def to_money_from_decimal(value)
      raise "Value must be an Decimal (#{value})" unless value.is_a? BigDecimal
      value.to_money(self).freeze
    end

    def to_money_from_units(value)
      raise "Value must be an Integer (#{value})" unless value.is_a? Integer
      Money.new(value, self).freeze
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
  end
end
# rubocop:enable Style/ClassAndModuleChildren

Money.locale_backend = :i18n
Money.default_currency = :RUB
Money.default_bank = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN

#CURRENCIES_PATH = Rails.root.join './config/money_currencies.yml'

#currencies = Psych
#.load(File.read(CURRENCIES_PATH))
#.each_with_object({}) { |values, hash| hash[values.first.to_sym] = values.second.symbolize_keys.reverse_merge(iso_code: values.first.upcase) }
#.each_with_index { |data, index| data.second.reverse_merge! priority: index }

#Money::Currency::Loader.load! currencies
#Money::Currency.all
