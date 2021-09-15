# frozen_string_literal: true

class AddIndexToTransactionsKindes < ActiveRecord::Migration[5.2]
  def change
    add_index :transactions, %i[blockchain_id kind]
    add_index :transactions, %i[blockchain_id to]
    add_index :transactions, %i[blockchain_id from]
  end
end
