# frozen_string_literal: true

class AddNetworkFeeToWithdraws < ActiveRecord::Migration[6.0]
  def change
    add_column :withdraws, :network_fee, :decimal, precision: 36, scale: 18
  end
end
