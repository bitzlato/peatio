class AddCurrencyIdToPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    remove_column :blockchains, :id
    add_column :blockchains, :id, :primary_key
    add_reference :payment_addresses, :blockchain
    PaymentAddress.find_each do |pa|
      blockchain = Blockchain.find_by_key(
        Wallet.find(pa.wallet_id).currencies.where(parent_id: nil).first.blockchain_key
      ) || raise("no blockchain for payment_address_id=#{pa.id}")
      PaymentAddress.where(id: pa.id).update_all blockchain_id: blockchain.id
    end
    change_column_null :payment_addresses, :blockchain_id, false
    remove_column :payment_addresses, :wallet_id
  end
end
