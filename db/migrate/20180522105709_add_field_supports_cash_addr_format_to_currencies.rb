# frozen_string_literal: true

class AddFieldSupportsCashAddrFormatToCurrencies < ActiveRecord::Migration[4.2]
  class Ccy < ApplicationRecord
    serialize :options, JSON
    self.table_name = 'currencies'
    self.inheritance_column = :disabled
  end

  def change
    Ccy.where(type: :coin).find_each do |ccy|
      ccy.update_columns \
        options: ccy.options.merge('supports_cash_addr_format' => ccy.code.in?(%w[bch bchd]))
    end
  end
end
