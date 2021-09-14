# frozen_string_literal: true

class AlterTradesCurrency < ActiveRecord::Migration[4.2]
  def change
    change_column :trades, :currency, :string, limit: 10
    rename_column :trades, :currency, :market_id
  end
end
