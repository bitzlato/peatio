class CreateGasRefuels < ActiveRecord::Migration[5.2]
  def change
    create_table :gas_refuels do |t|
      t.references :blockchain, foreign_key: true, null: false
      t.string :txid, null: false
      t.string :gas_wallet_address, null: false
      t.string :target_address, null: false
      t.bigint :amount, null: false
      t.string :status, null: false
      t.bigint :gas_price, null: false
      t.bigint :gas_limit, null: false
      t.bigint :gas_factor, null: false, default: 1
      t.jsonb :result_transaction

      t.timestamps
    end

    add_index :gas_refuels, %i[blockchain_id txid], unique: true
    add_index :gas_refuels, %i[blockchain_id gas_wallet_address]
    add_index :gas_refuels, %i[blockchain_id target_address]
  end
end
