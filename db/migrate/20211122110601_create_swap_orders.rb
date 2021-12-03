# frozen_string_literal: true

class CreateSwapOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :swap_orders do |t|
      t.string :from_unit, index: true, null: false
      t.string :to_unit, index: true, null: false
      t.references :order, index: true
      t.references :member, index: true, null: false
      t.string :market_id, limit: 20, null: false, index: true
      t.integer :state, null: false

      t.decimal :from_volume, precision: 36, scale: 18, null: false
      t.decimal :to_volume, precision: 36, scale: 18, null: false
      t.string  :request_unit, index: true, null: false
      t.decimal :request_volume, precision: 36, scale: 18, null: false
      t.decimal :request_price, precision: 36, scale: 18, null: false
      t.decimal :inverse_price, precision: 36, scale: 18, null: false
      t.timestamps
    end
  end
end
