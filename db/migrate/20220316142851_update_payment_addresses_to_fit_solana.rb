class UpdatePaymentAddressesToFitSolana < ActiveRecord::Migration[5.2]
  def change
    remove_index :payment_addresses, [:member_id, :blockchain_id, :parent_id]
    add_index :payment_addresses, [:member_id, :blockchain_id], unique: true, where: "(parent_id IS NULL AND archived_at IS NULL)"
    add_index :payment_addresses, [:member_id, :blockchain_id, :parent_id, :blockchain_currency_id], unique: true,
              where: "(parent_id IS NOT NULL AND archived_at IS NULL)", name: 'payment_addresses_member_blockchain_parent_blockchain_currency'
  end
end
