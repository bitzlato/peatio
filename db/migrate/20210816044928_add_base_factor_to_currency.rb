# frozen_string_literal: true

class AddBaseFactorToCurrency < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :base_factor, :bigint

    Currency.find_each do |c|
      c.update base_factor: c.money_currency.base_factor

      Rails.logger.debug { "precision for #{c.id} is difference #{c.precision} <> #{c.money_currency.precision}" } unless c.read_attribute(:precision) == c.money_currency.precision
    end

    change_column_null :currencies, :base_factor, false
  end
end
