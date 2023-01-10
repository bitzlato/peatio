# frozen_string_literal: true

FactoryBot.define do
  factory :blockchain do
    sequence(:key) { |n| "blockchain#{n}" }
    sequence(:name) { |n| "Blockchain ##{n}" }
    height { 1 }
    status { 'active' }
    gateway_klass { DummyGateway.name }
    client_options { { token_gas_limit: 110_000, base_gas_limit: 11_000, gas_factor: 1 } }

    trait 'bitzlato' do
      key                     { 'bitzlato' }
      name                    { 'bitzlato' }
      height                  { 2_500_000 }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      gateway_klass           { BitzlatoGateway.name }
    end

    trait 'dummy' do
      key                     { 'dummy' }
      name                    { 'dummy' }
      height                  { 2_500_000 }
      explorer_address        { 'https://etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      gateway_klass           { DummyGateway.name }
    end

    trait 'eth-rinkeby' do
      key                     { 'eth-rinkeby' }
      name                    { 'Ethereum Rinkeby' }
      gateway_klass { EthereumGateway.name }
      height                  { 2_500_000 }
      explorer_address        { 'https://etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      address_type            { 'ethereum' }
    end

    trait 'eth-kovan' do
      key                     { 'eth-kovan' }
      gateway_klass { EthereumGateway.name }
      name                    { 'Ethereum Kovan' }
      height                  { 2_500_000 }
      explorer_address        { 'https://kovan.etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://kovan.etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'eth-ropsten' do
      key                     { 'eth-ropsten' }
      name                    { 'Ethereum Ropsten' }
      gateway_klass { EthereumGateway.name }
      height                  { 2_500_000 }
      explorer_address        { 'https://ropsten.etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://ropsten.etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      address_type            { 'ethereum' }
    end

    trait 'bsc-testnet' do
      key                     { 'bsc-testnet' }
      gateway_klass           { BinanceGateway.name }
      name                    { 'Binance Testnet' }
      height                  { 1_350_000 }
      explorer_address        { 'https://blockchain.info/address/#{address}' }
      explorer_transaction    { 'https://blockchain.info/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'btc-testnet' do
      key                     { 'btc-testnet' }
      gateway_klass           { BitcoinGateway.name }
      name                    { 'Bitcoin Testnet' }
      height                  { 1_350_000 }
      explorer_address        { 'https://blockchain.info/address/#{address}' }
      explorer_transaction    { 'https://blockchain.info/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'btc-bz-testnet' do
      key                     { 'btc-bz-testnet' }
      gateway_klass           { BitzlatoGateway.name }
      name                    { 'Bitcoin BZ Testnet' }
      height                  { 1 }
      explorer_address        { 'https://blockchain.info/address/#{address}' }
      explorer_transaction    { 'https://blockchain.info/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'fake-testnet' do
      key                     { 'fake-testnet' }
      name                    { 'Fake Testnet' }
      height                  { 1 }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      gateway_klass           { DummyGateway.name }
    end

    trait 'tron-testnet' do
      key                     { 'tron-testnet' }
      name                    { 'Tron Testnet' }
      gateway_klass           { TronGateway.name }
      height                  { 2_500_000 }
      explorer_address        { 'https://nile.tronscan.org/#/address/\#{address}' }
      explorer_transaction    { 'https://nile.tronscan.org/#/transaction/\#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      address_type            { 'tron' }
    end

    trait 'sol-testnet' do
      key                     { 'sol-testnet' }
      name                    { 'sol Testnet' }
      gateway_klass           { SolanaGateway.name }
      height                  { 2_500_000 }
      explorer_address        { 'https://solscan.org/#/address/\#{address}' }
      explorer_transaction    { 'https://solscan.org/#/transaction/\#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      address_type            { 'sol' }
    end
  end
end
