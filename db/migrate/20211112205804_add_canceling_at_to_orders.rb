# frozen_string_literal: true

class AddCancelingAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :canceling_at, :timestamp
  end
end
