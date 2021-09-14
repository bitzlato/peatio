# frozen_string_literal: true

class AddKindToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :kind, :string, null: false, default: :none

    add_index :transactions, :kind
    add_index :transactions, %i[blockchain_id kind]
  end
end
