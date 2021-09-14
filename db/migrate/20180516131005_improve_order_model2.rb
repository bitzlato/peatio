# frozen_string_literal: true

class ImproveOrderModel2 < ActiveRecord::Migration[4.2]
  def change
    add_index :orders, %i[type market_id]
    add_index :orders, %i[type member_id]
  end
end
