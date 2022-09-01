# frozen_string_literal: true

class AddCurrencyIdToPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    remove_column :blockchains, :id
    add_column :blockchains, :id, :primary_key
    add_reference :payment_addresses, :blockchain
    change_column_null :payment_addresses, :blockchain_id, false
    remove_column :payment_addresses, :wallet_id
  end
end
