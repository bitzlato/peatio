# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    trait :usd do
      code                 { 'usd' }
      name                 { 'US Dollar' }
      type                 { 'fiat' }
      precision            { 2 }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.1 }
      position             { 1 }
      options              { {} }
    end

    trait :eur do
      code                 { 'eur' }
      name                 { 'Euro' }
      type                 { 'fiat' }
      precision            { 8 }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.1 }
      position             { 2 }
      visible              { false }
      options              { {} }
    end

    trait :btc do
      code                 { 'btc' }
      name                 { 'Bitcoin' }
      type                 { 'coin' }
      withdraw_limit_24h   { 0.1 }
      withdraw_limit_72h   { 1 }
      withdraw_fee         { 0.01 }
      position             { 3 }
      options              { {} }
    end

    trait :btc_bz do
      code                 { 'btc_bz' }
      name                 { 'Bitcoin' }
      type                 { 'coin' }
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
    end

    trait :eth do
      code                 { 'eth' }
      name                 { 'Ethereum' }
      type                 { 'coin' }
      withdraw_limit_24h   { 0.1 }
      withdraw_limit_72h   { 1 }
      withdraw_fee         { 0.025 }
      position             { 4 }
      options { { gas_price: 1_000_000_000 } }
    end

    trait :trst do
      code                 { 'trst' }
      name                 { 'WeTrust' }
      type                 { 'coin' }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.025 }
      position             { 5 }
      options { { gas_price: 1_000_000_000 } }
    end

    trait :usdt do
      code                 { 'usdt' }
      name                 { 'usdt' }
      type                 { 'coin' }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.025 }
      position             { 6 }
      options { {} }
    end

    trait :ring do
      code                 { 'ring' }
      name                 { 'Evolution Land Global Token' }
      type                 { 'coin' }
      withdraw_limit_24h   { 100 }
      withdraw_limit_72h   { 1000 }
      withdraw_fee         { 0.025 }
      position             { 6 }
      options { {} }
    end

    trait :mdt do
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
    end

    trait :'usdt-erc20' do
      name { 'USDT(ERC20)' }
    end
  end
end
