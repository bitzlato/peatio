# frozen_string_literal: true

FactoryBot.define do
  factory :deposit do
    member { create(:member, :level_3) }
    amount { Kernel.rand(100..10_000).to_d }

    factory :deposit_btc, class: 'Deposits::Coin' do
      blockchain
      currency { find_or_create :currency, :btc, id: :btc }
      address { create(:payment_address, :btc_address).address }
      txid { Faker::Lorem.characters(64) }
      txout { 0 }
      block_number { rand(1..1_349_999) }
    end

    factory :deposit_btc_bz, class: 'Deposits::Coin' do
      blockchain { find_or_create(:blockchain, 'btc-bz-testnet', key: 'btc-bz-testnet') }
      currency { find_or_create :currency, :btc_bz, id: 'btc_bz' }
      address { create(:payment_address, :btc_address).address }
      txid { Faker::Lorem.characters(64) }
      txout { 0 }
      block_number { rand(1..1_349_999) }
    end

    factory :deposit_usd, class: 'Deposits::Fiat' do
      blockchain
      currency { find_or_create :currency, :usd, id: :usd }
    end

    trait :deposit_btc do
      type { Deposits::Coin }
      blockchain { find_or_create(:blockchain, 'btc-testnet', key: 'btc-testnet') }
      currency { find_or_create :currency, :btc, id: :btc }
      address { create(:payment_address, :btc_address).address }
      txid { Faker::Lorem.characters(64) }
      txout { 0 }
    end

    trait :deposit_eth do
      type { Deposits::Coin }
      blockchain { find_or_create(:blockchain, 'eth-rinkeby', key: 'eth-rinkeby') }
      currency { find_or_create :currency, :eth, id: :eth }
      member { create(:member, :level_3, :barong) }
      address { create(:payment_address, :eth_address).address }
      txid { Faker::Lorem.characters(64) }
      txout { 0 }
    end

    trait :deposit_trst do
      type { Deposits::Coin }
      currency { find_or_create :currency, :trst, id: :trst }
      member { create(:member, :level_3, :barong) }
      address { create(:payment_address, :trst_address).address }
      txid { Faker::Lorem.characters(64) }
      txout { 0 }
    end

    trait :deposit_ring do
      type { Deposits::Coin }
      currency { find_or_create :currency, :ring, id: :ring }
      member { create(:member, :level_3, :barong) }
      address { create(:payment_address, :trst_address).address }
      txid { Faker::Lorem.characters(64) }
      txout { 0 }
    end
  end
end
