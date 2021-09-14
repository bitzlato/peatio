# frozen_string_literal: true

FactoryBot.define do
  factory :payment_address do
    address { Faker::Blockchain::Bitcoin.address }
    member { create(:member, :level_3) }
    association :blockchain

    trait :btc_address do
      member { create(:member, :level_3) }
      association :blockchain, strategy: :find_or_create, key: 'btc-testnet'
    end

    trait :eth_address do
      member { create(:member, :level_3) }
      association :blockchain, strategy: :find_or_create, key: 'eth-rinkeby'
    end

    trait :trst_address do
      member { create(:member, :level_3) }
      association :blockchain, strategy: :find_or_create, key: 'eth-rinkeby'
    end

    trait :ring_address do
      member { create(:member, :level_3) }
      association :blockchain, strategy: :find_or_create, key: 'eth-rinkeby'
    end

    factory :btc_payment_address,  traits: [:btc_address]
    factory :eth_payment_address,  traits: [:eth_address]
    factory :trst_payment_address, traits: [:trst_address]
    factory :ring_payment_address, traits: [:ring_address]
  end
end
