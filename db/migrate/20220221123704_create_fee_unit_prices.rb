# frozen_string_literal: true

class CreateFeeUnitPrices < ActiveRecord::Migration[5.2]
  def change
    create_table :fee_unit_prices do |t|
      t.references :blockchain, null: false
      t.bigint :price, null: false
      t.datetime :created_at, null: false
    end
  end
end
