# frozen_string_literal: true

class Numeric
  def to_money(currency)
    currency = Money::Currency.find!(currency) unless currency.is_a? Money::Currency
    Money.new(self * currency.subunit_to_unit, currency)
  end
end
