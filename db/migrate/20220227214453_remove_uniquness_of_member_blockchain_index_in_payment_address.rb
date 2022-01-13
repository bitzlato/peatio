class RemoveUniqunessOfMemberBlockchainIndexInPaymentAddress < ActiveRecord::Migration[5.2]
  def change
    remove_index :payment_addresses, [:member_id, :blockchain_id]
    add_index :payment_addresses, [:member_id, :blockchain_id]
  end
end
