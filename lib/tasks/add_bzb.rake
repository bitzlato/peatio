# encoding: UTF-8
# frozen_string_literal: true

namespace :bzb_blockchain do
  desc 'Add Bzb blockchain'

  task create: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.create!({
        key: 'bitzlato-mainnet',
        name: 'Bitzlato (BZB)',
        gateway_klass: 'EthereumGateway',
        server: 'http://bzb.local:31018/',
        height: 1432985,
        min_confirmations: 6,
        explorer: {
          'address' => 'https://explorer-pos.bzbchain.com/address/#{address}/transactions',
          'transaction' => 'https://explorer-pos.bzbchain.com/tx/#{txid}/internal-transactions',
          'contract_address' => 'https://explorer-pos.bzbchain.com/token/#{contract_address}/token-transfers'
        },
        status: 'disabled'
      })

      blockchain_address = blockchain.create_address!

      wallet = Wallet.create!({
        address: blockchain_address[:address],
        kind: 'hot',
        status: 'active',
        name: 'Bitzlato Hot Wallet',
        blockchain: blockchain,
        use_as_fee_source: true
      })

      bzb = Currency.create!({
                              id: 'bzb',
                              name: 'BZB',
                              type: 'coin',
                              options: {},
                              precision: 6,
                              visible: false,
                              deposit_enabled: true,
                              withdrawal_enabled: true,
                              min_collection_amount: 25.to_d,
                              withdraw_limit_24h: 10000.to_d,
                              withdraw_limit_72h: 30000.to_d,
                            })
      BlockchainCurrency.create!({
        currency: bzb,
        blockchain: blockchain,
        gas_limit: 24000,
        withdraw_fee: 3.to_d,
        min_deposit_amount: 5.to_d,
        options:  {  },
        base_factor: 1_000_000_000_000_000_000.to_d,
      })

      wallet.currencies = [bzb]
      wallet.save
    end
  end

  task activate: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.find_by(key: 'bitzlato-mainnet')
      blockchain.update! status: 'active'
      Currency.find('bzb').update! visible: true
    end
  end
end
