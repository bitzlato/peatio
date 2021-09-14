# frozen_string_literal: true

class AddTxDumpToWithdraws < ActiveRecord::Migration[5.2]
  def change
    add_column :withdraws, :tx_dump, :jsonb
  end
end
