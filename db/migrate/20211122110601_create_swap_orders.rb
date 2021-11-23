# frozen_string_literal: true

class CreateSwapOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :swap_orders do |t|
      t.uuid :uuid, index: { unique: true }, null: false, default: 'gen_random_uuid()'
      t.references :member, index: true, null: false
      t.string :market_id, limit: 20, null: false, index: true
      t.integer :state, null: false
      t.decimal :price, precision: 32, scale: 16, null: false
      t.decimal :volume, precision: 32, scale: 16, null: false
      t.integer :side, null: false
      t.timestamps
    end
  end
end
