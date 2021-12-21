# frozen_string_literal: true

class AddTronBlockchain < ActiveRecord::Migration[5.2]
  def change
    blockchain = Blockchain.create!({
                                      key: 'tron-mainnet',
                                      name: 'Tron Mainnet',
                                      gateway_klass: 'TronGateway',
                                      server: 'http://localhost:8090',
                                      height: 37_347_328,
                                      min_confirmations: 6,
                                      explorer: {
                                        'address' => 'https://tronscan.org/#/address/#{address}', # rubocop:disable Lint/InterpolationCheck
                                        'transaction' => 'https://tronscan.org/#/transaction/#{txid}' # rubocop:disable Lint/InterpolationCheck
                                      },
                                      status: 'active'
                                    })

    blockchain_address = blockchain.create_address!
    Wallet.create!({
                     address: blockchain_address[:address],
                     kind: 'hot',
                     status: 'active',
                     name: 'Tron Hot Wallet',
                     settings: { 'uri' => 'http://localhost:8090' },
                     blockchain: blockchain,
                     use_as_fee_source: true
                   })

    trx = Currency.create!({
                             id: 'trx',
                             name: 'TRX(TRON)',
                             type: 'coin',
                             options: { bandwidth_limit: 280 },
                             precision: 6,
                             visible: true,
                             deposit_enabled: true,
                             withdrawal_enabled: true,
                             min_deposit_amount: 5.to_d,
                             min_collection_amount: 10.to_d,
                             withdraw_limit_24h: 500_000.to_d,
                             withdraw_limit_72h: 1_500_000.to_d,
                             base_factor: 1_000_000.to_d
                           })
    trx_bc = BlockchainCurrency.create!(currency: trx, blockchain: blockchain, gas_limit: 5_000_000)

    usdt = Currency.create!({
                              id: 'usdt-trc20',
                              name: 'USDT(TRON)',
                              type: 'coin',
                              options: { bandwidth_limit: 350, energy_limit: 15_000, trc20_contract_address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t' },
                              precision: 6,
                              visible: true,
                              deposit_enabled: true,
                              withdrawal_enabled: true,
                              min_deposit_amount: 2.to_d,
                              min_collection_amount: 4.to_d,
                              withdraw_limit_24h: 6_000.to_d,
                              withdraw_limit_72h: 18_000.to_d,
                              base_factor: 1_000_000.to_d,
                              contract_address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
                            })
    BlockchainCurrency.create!(currency: usdt, blockchain: blockchain, gas_limit: 10_000_000, parent: trx_bc, contract_address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t')
  end
end
