# frozen_string_literal: true

class RemoveGasRefuelingStateFromPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    remove_column :payment_addresses, :gas_refueling_state
  end
end
