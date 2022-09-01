# frozen_string_literal: true

class CreateCurrenciesWallets < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        create_table :currencies_wallets, id: false do |t| # rubocop:disable Rails/CreateTableWithTimestamps
          t.string :currency_id, index: true
          t.integer :wallet_id, index: true
        end
        add_index :currencies_wallets, %i[currency_id wallet_id], unique: true

        add_reference :payment_addresses, :member, index: true, after: :id
        add_reference :payment_addresses, :wallet, index: true, after: :member_id

        change_column_default :currencies, :options, nil
        remove_column :wallets, :currency_id
        remove_index :payment_addresses, column: %i[currency_id address]
        remove_column :payment_addresses, :currency_id
        remove_column :payment_addresses, :account_id

        case ActiveRecord::Base.connection.adapter_name
        when 'Mysql2'
          change_column :currencies, :options, :json
        when 'PostgreSQL'
          execute 'ALTER TABLE currencies ALTER COLUMN options TYPE json USING (options::json)'
        else
          raise "Unsupported adapter: #{ActiveRecord::Base.connection.adapter_name}"
        end
      end

      dir.down do
        add_column :wallets, :currency_id, :string, limit: 10, after: :blockchain_key

        # For payment_addresses user will need to generate new addresses
        add_column :payment_addresses, :currency_id, :string, limit: 10, after: :id
        add_column :payment_addresses, :account_id, :integer, after: :currency_id

        remove_column :payment_addresses, :member_id
        remove_column :payment_addresses, :wallet_id
        change_column :currencies, :options, limit: 1000, default: '{}'
        drop_table :currencies_wallets
      end
    end
  end
end
