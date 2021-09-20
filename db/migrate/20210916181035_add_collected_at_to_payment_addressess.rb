# frozen_string_literal: true

class AddCollectedAtToPaymentAddressess < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_addresses, :collected_at, :timestamp
    add_column :payment_addresses, :gas_refueled_at, :timestamp
  end
end
