# frozen_string_literal: true

class AddMinPriceToMarket < ActiveRecord::Migration[4.2]
  def change
    add_column :markets, :max_bid, :decimal, precision: 17, scale: 16, after: :bid_fee
    add_column :markets, :min_ask, :decimal, null: false, default: 0, precision: 17, scale: 16, after: :max_bid
  end
end
