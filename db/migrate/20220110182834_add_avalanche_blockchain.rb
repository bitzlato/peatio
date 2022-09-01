# frozen_string_literal: true

# rubocop:disable Lint/InterpolationCheck
class AddAvalancheBlockchain < ActiveRecord::Migration[5.2]
  def change
    change_column :currencies, :id, :string, limit: 15

    Blockchain.reset_column_information # fixes tests when old migration cache model's columns
    Blockchain.create!({
                         key: 'avax-mainnet',
                         name: 'Avalanche',
                         gateway_klass: 'EthereumGateway',
                         height: 9_399_120,
                         min_confirmations: 6,
                         explorer: {
                           'address' => 'https://snowtrace.io/address/#{address}',
                           'transaction' => 'https://snowtrace.io/tx/#{txid}',
                           'contract_address' => 'https://snowtrace.io/token/#{contract_address}'
                         },
                         status: 'active',
                         address_type: 'ethereum',
                         client_options: {
                           gas_factor: '1'
                         },
                         chain_id: 43_114
                       })
  end
end
# rubocop:enable Lint/InterpolationCheck
