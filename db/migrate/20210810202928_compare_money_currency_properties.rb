# frozen_string_literal: true

class CompareMoneyCurrencyProperties < ActiveRecord::Migration[5.2]
  def change
    Currency.find_each do |c|
      raise "Currency #{c.id} has no money_currency" if c.money_currency.nil?
      raise "Currency #{c.id} and money currency base_factor are not same" unless c.read_attribute(:base_factor) == c.money_currency.base_factor
    end
    remove_column :currencies, :base_factor
  end
end
