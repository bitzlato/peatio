# frozen_string_literal: true

class CreateBlockchainCurrencies < ActiveRecord::Migration[5.2]
  def up
    create_table :blockchain_currencies do |t|
      t.references :blockchain, index: false, foreign_key: true, null: false
      t.references :currency, type: :string, limit: 10, foreign_key: true, null: false
      t.string :contract_address
      t.bigint :gas_limit
      t.bigint :parent_id

      t.timestamps

      t.index %i[blockchain_id currency_id], unique: true
    end

    add_foreign_key :blockchain_currencies, :blockchain_currencies, column: :parent_id
    execute 'ALTER TABLE blockchain_currencies ADD CONSTRAINT blockchain_currencies_contract_address CHECK (parent_id IS NOT NULL AND contract_address IS NOT NULL OR parent_id IS NULL AND contract_address IS NULL)'
  end

  def down
    drop_table :blockchain_currencies
  end
end
