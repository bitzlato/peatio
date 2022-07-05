# frozen_string_literal: true

class AddFlexibleFeeToBlockchains < ActiveRecord::Migration[6.0]
  def change
    add_column :blockchains, :flexible_fee, :boolean, default: false
  end
end
