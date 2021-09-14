# frozen_string_literal: true

class AddTIDToDeposit < ActiveRecord::Migration[4.2]
  def change
    add_column :deposits, :tid, :string, limit: 64
    execute %{UPDATE deposits SET tid = CONCAT('TID', id, currency_id, member_id) WHERE tid IS NULL}
    change_column :deposits, :tid, :string, null: false, index: { unique: true }, limit: 64
  end
end
