# frozen_string_literal: true

class AlterCurrency < ActiveRecord::Migration[4.2]
  def change
    change_column :orders, :currency, :string, limit: 10
  end
end
