class RemoveUniqunessOfMemberBlockchainIndexInPaymentAddress < ActiveRecord::Migration[5.2]
  def change
    remove_index :payment_addresses, [:member_id, :blockchain_id]
    add_index :payment_addresses, [:member_id, :blockchain_id, :parent_id], unique: true, name: 'index_payment_addresses_unique_member_blockchain_parent'
  end
end
