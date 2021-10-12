# frozen_string_literal: true

class AddOpenOrdersLimitToTradingFee < ActiveRecord::Migration[5.2]
  def change
    add_column :trading_fees, :open_orders_limit, :integer, null: false, default: 5

    TradingFee.where(group: 'market-makers').update open_orders_limit: 50
    TradingFee.where(group: 'vip-3').update open_orders_limit: 10
  end
end
