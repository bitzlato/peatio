# frozen_string_literal: true

class AddAllowanceEnabledToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :allowance_enabled, :boolean, default: false, null: false
  end
end
