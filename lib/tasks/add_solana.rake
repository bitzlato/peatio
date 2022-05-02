# encoding: UTF-8
# frozen_string_literal: true

namespace :solana_blockchain do
  desc 'Add Solana blockchain'

  task create: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.create!({
        key: 'solana-mainnet',
        name: 'Solana (SPL)',
        gateway_klass: 'SolanaGateway',
        server: 'https://api.testnet.solana.com',
        height: 38187307,
        min_confirmations: 6,
        explorer: {
          'address' => 'https://solscan.io/address/#{address}',
          'transaction' => 'https://solscan.io/tx/#{txid}',
          'contract_address' => 'https://solscan.io/account/#{contract_address}'
        },
        status: 'disabled'
      })

      blockchain_address = blockchain.create_address!

      wallet = Wallet.create!({
        address: blockchain_address[:address],
        kind: 'hot',
        status: 'active',
        name: 'Solana Native Hot Wallet',
        settings: { 'uri' => 'https://api.testnet.solana.com' },
        blockchain: blockchain,
        use_as_fee_source: true
      })

      sol = Currency.create!({
                              id: 'sol',
                              name: 'SOL',
                              type: 'coin',
                              options: {},
                              precision: 9,
                              visible: false,
                              deposit_enabled: true,
                              withdrawal_enabled: true,
                              min_collection_amount: 0.1.to_d,
                              withdraw_limit_24h: 300.to_d,
                              withdraw_limit_72h: 1000.to_d,
                            })
      wsol = Currency.create!({
                               id: 'wsol',
                               name: 'SOL',
                               type: 'coin',
                               options: {},
                               precision: 9,
                               visible: false,
                               deposit_enabled: true,
                               withdrawal_enabled: true,
                               min_collection_amount: 0.1.to_d,
                               withdraw_limit_24h: 300.to_d,
                               withdraw_limit_72h: 1000.to_d,
                             })

      sol_bc = BlockchainCurrency.create!({
        currency: sol,
        blockchain: blockchain,
        gas_limit: 20000,
        withdraw_fee: 15.to_d,
        min_deposit_amount: 0.05.to_d,
        options:  {  },
        base_factor: 1_000_000.to_d,
      })

      BlockchainCurrency.create!({
        currency: Currency.find('wsol'),
        blockchain: blockchain,
        gas_limit: 20000,
        parent: sol_bc,
        contract_address: 'So11111111111111111111111111111111111111112',
        withdraw_fee: 15.to_d,
        min_deposit_amount: 0.05.to_d,
        options:  {  },
        base_factor: 1_000_000_000.to_d,
      })

      BlockchainCurrency.create!({
        currency: Currency.find('usdt'),
        blockchain: blockchain,
        gas_limit: 20000,
        parent: sol_bc,
        contract_address: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
        withdraw_fee: 1.to_d,
        min_deposit_amount: 1.to_d,
        base_factor: 1_000_000.to_d,
        options: { },
      })

      wallet.currencies = [sol]
      wallet.save
    end
  end

  task setup: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.find_by_key!('solana-mainnet')
      hot_wallet  = blockchain.hot_wallet
      sol = Currency.find('sol')
      wsol = Currency.find('wsol')
      usdt = Currency.find('usdt')
      wsol_bc = blockchain.blockchain_currencies.find_by!(currency: wsol)
      usdt_bc = blockchain.blockchain_currencies.find_by!(currency: usdt)

      wsol_address = blockchain.gateway.find_or_create_token_account(hot_wallet.address, wsol_bc.contract_address, blockchain.hot_wallet)
      wsol_wallet = Wallet.create!({
                                     address: wsol_address,
                                     kind: 'hot',
                                     status: 'active',
                                     name: 'Solana WSOL Hot Wallet',
                                     settings: { 'uri' => 'https://api.testnet.solana.com' },
                                     blockchain: blockchain,
                                     use_as_fee_source: true,
                                     parent: hot_wallet
                                   })
      wsol_wallet.currencies = [sol, wsol]
      wsol_wallet.save

      usdt_address = blockchain.gateway.find_or_create_token_account(hot_wallet.address, usdt_bc.contract_address, blockchain.hot_wallet)
      usdt_wallet = Wallet.create!({
                                     address: usdt_address,
                                     kind: 'hot',
                                     status: 'active',
                                     name: 'Solana USDT Hot Wallet',
                                     settings: { 'uri' => 'https://api.testnet.solana.com' },
                                     blockchain: blockchain,
                                     use_as_fee_source: true,
                                     parent: hot_wallet
                                   })
      usdt_wallet.currencies = [sol, usdt]
      usdt_wallet.save
    end
  end

  task activate: :environment do
    ActiveRecord::Base.transaction do
      blockchain = Blockchain.find_by(key: 'solana-mainnet')
      blockchain.update! status: 'active'
      Currency.find('wsol').update! visible: true
    end
  end
end
