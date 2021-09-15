# frozen_string_literal: true

class AddBlockchainToWithdraws < ActiveRecord::Migration[5.2]
  def change
    add_reference :withdraws, :blockchain, foreign_key: true

    Withdraw.find_each do |w|
      w.update_columns blockchain_id: w.currency.blockchain.id
    end

    change_column_null :withdraws, :blockchain_id, false
  end
end
