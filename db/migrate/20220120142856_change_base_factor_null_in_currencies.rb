# frozen_string_literal: true

class ChangeBaseFactorNullInCurrencies < ActiveRecord::Migration[5.2]
  def change
    change_column_null :currencies, :base_factor, true
  end
end
