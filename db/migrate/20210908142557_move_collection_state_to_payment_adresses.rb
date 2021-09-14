# frozen_string_literal: true

class MoveCollectionStateToPaymentAdresses < ActiveRecord::Migration[5.2]
  def change
    remove_column :deposits, :collection_state
    add_column :payment_addresses, :collection_state, :string, null: false, default: 'none'
  end
end
