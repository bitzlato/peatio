class AddParentToPaymentAddress < ActiveRecord::Migration[5.2]
  def change
    add_reference :payment_addresses, :parent, foreign_key: {to_table: :payment_addresses}
    add_reference :payment_addresses, :blockchain_currency
  end
end
