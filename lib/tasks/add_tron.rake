# encoding: UTF-8
# frozen_string_literal: true

namespace :tron_blockchain do
  desc 'Add Tron blockchain'

  task activate: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.find_by(key: 'tron-mainnet')
      blockchain.update! status: 'active'
      Currency.find('trx').update! visible: true
    end
  end

  task add: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.create!({
                                       key: 'tron-mainnet',
                                       name: 'Tron Mainnet',
                                       gateway_klass: 'TronGateway',
                                       server: 'http://localhost:8090',
                                       height: 38187307,
                                       min_confirmations: 6,
                                       explorer: {
                                         'address' => 'https://tronscan.org/#/address/#{address}',
                                         'transaction' => 'https://tronscan.org/#/transaction/#{txid}'
                                       },
                                       status: 'disabled'
                                     })

      blockchain_address = blockchain.create_address!

      wallet = Wallet.create!({
                      address: blockchain_address[:address],
                      kind: 'hot',
                      status: 'active',
                      name: 'Tron Hot Wallet',
                      blockchain: blockchain,
                      use_as_fee_source: true
                    })

      trx = Currency.create!({
                              id: 'trx',
                              name: 'TRX(TRON)',
                              type: 'coin',
                              options: {},
                              precision: 6,
                              visible: false,
                              deposit_enabled: true,
                              withdrawal_enabled: true,
                              min_collection_amount: 10.to_d,
                              withdraw_limit_24h: 500_000.to_d,
                              withdraw_limit_72h: 1_500_000.to_d,
                            })

      wallet.currencies << trx
      wallet.currencies << Currency.find('usdt')

      trx_bc = BlockchainCurrency.create!({
        currency: trx,
        blockchain: blockchain,
        gas_limit: 15_000_000,
        withdraw_fee: 15.to_d,
        min_deposit_amount: 5.to_d,
        options:  { bandwidth_limit: 280 },
        base_factor: 1_000_000.to_d,
      })

      BlockchainCurrency.create!({
        currency: Currency.find('usdt'),
        blockchain: blockchain,
        gas_limit: 15_000_000,
        parent: trx_bc,
        contract_address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
        withdraw_fee: 1.to_d,
        min_deposit_amount: 2.to_d,
        base_factor: 1_000_000.to_d,
        options: { bandwidth_limit: 350, energy_limit: 15_000 },
      })
    end
  end
end
