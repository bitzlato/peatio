# frozen_string_literal: true

# rubocop:disable Lint/InterpolationCheck
class AddAvalancheBlockchain < ActiveRecord::Migration[5.2]
  def change
    change_column :currencies, :id, :string, limit: 15

    [Blockchain, Currency, Wallet].each(&:reset_column_information) # fixes tests when old migration cache model's columns
    Blockchain.create!({
                         key: 'avax-mainnet',
                         name: 'Avalanche',
                         gateway_klass: 'EthereumGateway',
                         server: 'https://api.avax.network/ext/bc/C/rpc',
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
    currencies = Currency.create!([
                                    {
                                      id: 'avax',
                                      name: 'Avalanche',
                                      blockchain_key: 'avax-mainnet',
                                      type: :coin,
                                      visible: false,
                                      deposit_enabled: true,
                                      withdrawal_enabled: true,
                                      deposit_fee: 0,
                                      withdraw_fee: 0,
                                      precision: 6,
                                      subunits: 18,
                                      base_factor: 1_000_000_000_000_000_000,
                                      withdraw_limit_24h: 500,
                                      withdraw_limit_72h: 1500,
                                      min_deposit_amount: 0.05,
                                      min_collection_amount: 0.1,
                                      options: {
                                        gas_limit: 30_000,
                                        gas_price: 25_000_000_000
                                      }
                                    },
                                    {
                                      id: 'wavax-arc20',
                                      name: 'WAVAX',
                                      blockchain_key: 'avax-mainnet',
                                      type: :coin,
                                      visible: false,
                                      deposit_enabled: true,
                                      withdrawal_enabled: true,
                                      deposit_fee: 0,
                                      withdraw_fee: 0,
                                      precision: 6,
                                      subunits: 18,
                                      base_factor: 1_000_000_000_000_000_000,
                                      withdraw_limit_24h: 6000,
                                      withdraw_limit_72h: 18_000,
                                      min_deposit_amount: 1,
                                      min_collection_amount: 10,
                                      contract_address: '0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7',
                                      options: {
                                        gas_limit: 30_000,
                                        gas_price: 25_000_000_000
                                      }
                                    },
                                    {
                                      id: 'usdte-arc20',
                                      name: 'USDT.e',
                                      blockchain_key: 'avax-mainnet',
                                      type: :coin,
                                      visible: false,
                                      deposit_enabled: true,
                                      withdrawal_enabled: true,
                                      deposit_fee: 0,
                                      withdraw_fee: 0,
                                      precision: 6,
                                      subunits: 6,
                                      base_factor: 1_000_000,
                                      withdraw_limit_24h: 6000,
                                      withdraw_limit_72h: 18_000,
                                      min_deposit_amount: 1,
                                      min_collection_amount: 10,
                                      contract_address: '0xc7198437980c041c805a1edcba50c1ce5db95118',
                                      options: {
                                        gas_limit: 30_000,
                                        gas_price: 25_000_000_000
                                      }
                                    },
                                    {
                                      id: 'usdce-arc20',
                                      name: 'USDC.e',
                                      blockchain_key: 'avax-mainnet',
                                      type: :coin,
                                      visible: false,
                                      deposit_enabled: true,
                                      withdrawal_enabled: true,
                                      deposit_fee: 0,
                                      withdraw_fee: 0,
                                      precision: 6,
                                      subunits: 6,
                                      base_factor: 1_000_000,
                                      withdraw_limit_24h: 500,
                                      withdraw_limit_72h: 1500,
                                      min_deposit_amount: 0.05,
                                      min_collection_amount: 0.1,
                                      contract_address: '0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664',
                                      options: {
                                        gas_limit: 30_000,
                                        gas_price: 25_000_000_000
                                      }
                                    }
                                  ])
    Wallet.create!({
                     name: 'Avalanche deposit',
                     blockchain_key: 'avax-mainnet',
                     kind: 'deposit',
                     balance: {},
                     currencies: currencies,
                     max_balance: 0.0,
                     status: 'active',
                     settings: {
                       'uri' => 'https://api.avax.network/ext/bc/C/rpc'
                     },
                     use_as_fee_source: true,
                     enable_invoice: false
                   })
  end
end
# rubocop:enable Lint/InterpolationCheck
