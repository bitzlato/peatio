# frozen_string_literal: true

FactoryBot.define do
  factory :blockchain_currency do
    blockchain factory: %i[blockchain eth-ropsten]
    currency factory: %i[currency usdt]

    trait :eth do
      subunits { 18 }
      gas_limit { 21_000 }
    end

    trait :trst do
      subunits { 6 }
      gas_limit { 90_000 }
      contract_address { '0x87099adD3bCC0821B5b151307c147215F839a110' }
    end

    trait :ring do
      subunits { 6 }
      gas_limit { 21_000 }
      contract_address { '0xf8720eb6ad4a530cccb696043a0d10831e2ff60e' }
    end
  end
end
