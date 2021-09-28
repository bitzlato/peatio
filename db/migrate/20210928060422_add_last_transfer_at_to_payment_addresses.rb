# frozen_string_literal: true

class AddLastTransferAtToPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_addresses, :last_transfer_try_at, :timestamp
    add_column :payment_addresses, :last_transfer_status, :string
  end
end
