class AddClientOptionsToBlockchain < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :client_options, :jsonb, null: false, default: {}
    Blockchain.where(key: 'eth-mainnet').update_all client_options: { refuel_gas_factor: 1.1, base_gas_limit: 22_000, token_gas_limit: 110_000 }
    Blockchain.where(key: 'bsc-mainnet').update_all client_options: { refuel_gas_factor: 1.1, base_gas_limit: 22_000, token_gas_limit: 220_000 }
  end
end
