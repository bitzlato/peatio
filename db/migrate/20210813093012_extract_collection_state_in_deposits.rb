# frozen_string_literal: true

class ExtractCollectionStateInDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :collection_state, :string, null: false, default: 'pending'

    Deposit.where(aasm_state: 'collected').update_all aasm_state: :dispatched, collection_state: :collected
    Deposit.where(aasm_state: 'fee_processing').update_all collection_state: :processing, aasm_state: :accepted
  end
end
