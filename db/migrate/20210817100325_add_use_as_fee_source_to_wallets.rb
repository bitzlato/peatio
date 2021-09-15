# frozen_string_literal: true

class AddUseAsFeeSourceToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :use_as_fee_source, :boolean, null: false, default: false
  end
end
