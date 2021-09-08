class AddGasRefuelingStateToPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_addresses, :gas_refueling_state, :string, null: false, default: 'none'
  end
end
