# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :blockchain do
    gateway_klass { DummyGateway.name }
    client_options          { {token_gas_limit: 110_000, base_gas_limit: 11_000, gas_factor: 1} }

    trait 'bitzlato' do
      key                     { 'bitzlato' }
      name                    { 'bitzlato' }
      server                  { 'http://127.0.0.1:1' }
      height                  { 2500000 }
      min_confirmations       { 6 }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
      gateway_klass           { BitzlatoGateway.name }
    end

    trait 'dummy' do
      key                     { 'dummy' }
      name                    { 'dummy' }
      server                  { 'http://127.0.0.1:1' }
      height                  { 2500000 }
      min_confirmations       { 6 }
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
      server                  { 'http://127.0.0.1:8545' }
      height                  { 2500000 }
      min_confirmations       { 6 }
      explorer_address        { 'https://etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'eth-kovan' do
      key                     { 'eth-kovan' }
      gateway_klass { EthereumGateway.name }
      name                    { 'Ethereum Kovan' }
      server                  { 'http://127.0.0.1:8545' }
      height                  { 2500000 }
      min_confirmations       { 6 }
      explorer_address        { 'https://kovan.etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://kovan.etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    #trait 'eth-mainet' do
      #key                     { 'eth-mainet' }
      #gateway_klass           { EthereumGateway.name }
      #name                    { 'Ethereum Mainet' }
      #server                  { 'http://127.0.0.1:8545' }
      #height                  { 2500000 }
      #min_confirmations       { 4 }
      #explorer_address        { 'https://etherscan.io/address/#{address}' }
      #explorer_transaction    { 'https://etherscan.io/tx/#{txid}' }
      #status                  { 'disabled' }
      #initialize_with         { Blockchain.find_or_create_by(key: key) }
    #end

    trait 'bsc-testnet' do
      key                     { 'btc-testnet' }
      gateway_klass           { BinanceGateway.name }
      name                    { 'Binance Testnet' }
      server                  { 'http://127.0.0.1:18332' }
      height                  { 1350000 }
      min_confirmations       { 1 }
      explorer_address        { 'https://blockchain.info/address/#{address}' }
      explorer_transaction    { 'https://blockchain.info/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'btc-testnet' do
      key                     { 'btc-testnet' }
      gateway_klass           { BitcoinGateway.name }
      name                    { 'Bitcoin Testnet' }
      server                  { 'http://127.0.0.1:18332' }
      height                  { 1350000 }
      min_confirmations       { 1 }
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
  end
end
