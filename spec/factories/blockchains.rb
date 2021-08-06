# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :blockchain do
    trait 'eth-rinkeby' do
      key                     { 'eth-rinkeby' }
      name                    { 'Ethereum Rinkeby' }
      client                  { 'geth' }
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
      name                    { 'Ethereum Kovan' }
      client                  { 'parity' }
      server                  { 'http://127.0.0.1:8545' }
      height                  { 2500000 }
      min_confirmations       { 6 }
      explorer_address        { 'https://kovan.etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://kovan.etherscan.io/tx/#{txid}' }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'eth-mainnet' do
      key                     { 'eth-mainnet' }
      name                    { 'Ethereum Mainet' }
      client                  { 'geth' }
      server                  { 'http://127.0.0.1:8545' }
      height                  { 2500000 }
      min_confirmations       { 4 }
      explorer_address        { 'https://etherscan.io/address/#{address}' }
      explorer_transaction    { 'https://etherscan.io/tx/#{txid}' }
      status                  { 'disabled' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end

    trait 'btc-testnet' do
      key                     { 'btc-testnet' }
      name                    { 'Bitcoin Testnet' }
      client                  { 'bitcoin' }
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
      client                  { 'fake' }
      height                  { 1 }
      status                  { 'active' }
      initialize_with         { Blockchain.find_or_create_by(key: key) }
    end
  end
end
