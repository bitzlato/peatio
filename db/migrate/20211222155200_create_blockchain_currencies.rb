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

    Blockchain.find_each do |blockchain|
      parent_currency = Currency.find_by(blockchain_id: blockchain.id, parent_id: nil)

      next unless parent_currency

      parent_blockchain_currency = BlockchainCurrency.create!(blockchain: blockchain, currency: parent_currency, gas_limit: parent_currency.gas_limit)
      Currency.where(blockchain_id: blockchain.id).where.not(parent_id: nil).find_each do |currency|
        BlockchainCurrency.create!(blockchain: blockchain, currency: currency, contract_address: currency.contract_address, gas_limit: currency.gas_limit, parent_id: parent_blockchain_currency.id)
      end
    end
  end

  def down
    drop_table :blockchain_currencies
  end
end
