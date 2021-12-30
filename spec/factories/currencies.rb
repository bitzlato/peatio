# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    trait :usd do
      code                 { 'usd' }
      name                 { 'US Dollar' }
      type                 { 'fiat' }
      base_factor          { 100 }
      precision            { 2 }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.1 }
      position             { 1 }
      options              { {} }
      association :blockchain, :dummy, strategy: :find_or_create, key: 'dummy'
    end

    trait :eur do
      code                 { 'eur' }
      name                 { 'Euro' }
      type                 { 'fiat' }
      base_factor          { 100 }
      precision            { 8 }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.1 }
      position             { 2 }
      visible              { false }
      options              { {} }
      association :blockchain, :dummy, strategy: :find_or_create, key: 'dummy'
    end

    trait :btc do
      code                 { 'btc' }
      name                 { 'Bitcoin' }
      type                 { 'coin' }
      subunits             { 8 }
      withdraw_limit_24h   { 0.1 }
      withdraw_limit_72h   { 1 }
      withdraw_fee         { 0.01 }
      position             { 3 }
      options              { {} }
      association :blockchain, 'btc-testnet', strategy: :find_or_create, key: 'btc-testnet'
    end

    trait :btc_bz do
      code                 { 'btc_bz' }
      name                 { 'Bitcoin' }
      type                 { 'coin' }
      subunits             { 8 }
      withdraw_limit_24h   { 0.1 }
      withdraw_limit_72h   { 1 }
      withdraw_fee         { 0.01 }
      position             { 3 }
      options              { {} }
      association :blockchain, 'btc-bz-testnet', strategy: :find_or_create, key: 'btc-bz-testnet'
    end

    trait :bnb do
      code                 { 'bnb' }
      name                 { 'bnb' }
      type                 { 'coin' }
      withdraw_limit_24h   { 0.1 }
      withdraw_limit_72h   { 1 }
      withdraw_fee         { 0.025 }
      position             { 4 }
      options { { gas_price: 1_000_000_000 } }
      association :blockchain, 'bsc-testnet', strategy: :find_or_create, key: 'bsc-testnet'
      after(:create) { |currency| currency.blockchain_currency.update!(gas_limit: 21_000) }
    end

    trait :eth do
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      subunits             { 18 }
      code                 { 'eth' }
      name                 { 'Ethereum' }
      type                 { 'coin' }
      withdraw_limit_24h   { 0.1 }
      withdraw_limit_72h   { 1 }
      withdraw_fee         { 0.025 }
      position             { 4 }
      options { { gas_price: 1_000_000_000 } }
      after(:create) { |currency| currency.blockchain_currency.update!(gas_limit: 21_000) }
    end

    trait :trst do
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      code                 { 'trst' }
      name                 { 'WeTrust' }
      type                 { 'coin' }
      subunits { 6 }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.025 }
      position             { 5 }
      options { { gas_price: 1_000_000_000 } }
      after(:create) { |currency| currency.blockchain_currency.update!(contract_address: '0x87099adD3bCC0821B5b151307c147215F839a110', gas_limit: 90_000, parent_id: find_or_create(:currency, 'eth', id: 'eth').blockchain_currency.id) }
    end

    trait :usdt do
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      code                 { 'usdt' }
      name                 { 'usdt' }
      type                 { 'coin' }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.025 }
      position             { 6 }
      options { {} }
      after(:create) { |currency| currency.blockchain_currency.update!(contract_address: '0xf8720eb6ad4a530cccb696043a0d10831e2ff60e', gas_limit: 21_000, parent_id: find_or_create(:currency, 'eth', id: 'eth').blockchain_currency.id) }
    end

    trait :ring do
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      code                 { 'ring' }
      name                 { 'Evolution Land Global Token' }
      type                 { 'coin' }
      subunits { 6 }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.025 }
      position             { 6 }
      options { {} }
      after(:create) { |currency| currency.blockchain_currency.update!(contract_address: '0xf8720eb6ad4a530cccb696043a0d10831e2ff60e', gas_limit: 21_000, parent_id: find_or_create(:currency, 'eth', id: 'eth').blockchain_currency.id) }
    end

    trait :mdt do
      association :blockchain, :dummy, strategy: :find_or_create, key: 'dummy'
      code                { 'mdt' }
      name                { 'mdt' }
      type                { 'coin' }
      withdraw_limit_24h  { 100 }
      withdraw_limit_72h  { 1000 }
      withdraw_fee        { 0.02 }
      position            { 7 }
      options             { {} }
    end

    trait :mcr do
      association :blockchain, :dummy, strategy: :find_or_create, key: 'dummy'
      code                { 'mcr' }
      name                { 'mcr' }
      type                { 'coin' }
      withdraw_limit_24h  { 100 }
      withdraw_limit_72h  { 1000 }
      withdraw_fee        { 0.02 }
      position            { 7 }
      options             { {} }
    end

    trait :fake do
      association :blockchain, :dummy, strategy: :find_or_create, key: 'dummy'
      code                { 'fake' }
      name                { 'Fake Coin' }
      type                { 'coin' }
      withdraw_limit_24h  { 100 }
      withdraw_limit_72h  { 1000 }
      withdraw_fee        { 0.02 }
      position            { 7 }
      options             { {} }
    end

    trait :xagm_cx do
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      code                { 'xagm.cx' }
      name                { 'XAGm.cx' }
      type                { 'coin' }
      withdraw_limit_24h  { 100 }
      withdraw_limit_72h  { 1000 }
      withdraw_fee        { 0.02 }
      position            { 8 }
      visible             { true }
      options             { {} }
      after(:create) { |currency| currency.blockchain_currency.update!(contract_address: '0x0', parent_id: find_or_create(:currency, 'eth', id: 'eth').blockchain_currency.id) }
    end

    trait :'usdt-erc20' do
      name { 'USDT(ERC20)' }
      subunits { 6 }
      after(:create) { |currency| currency.blockchain_currency.update!(contract_address: '0xdac17f958d2ee523a2206206994597c13d831ec7', parent_id: find_or_create(:currency, 'eth', id: 'eth').blockchain_currency.id) }
    end
  end
end
