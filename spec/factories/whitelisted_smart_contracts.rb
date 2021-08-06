# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :whitelisted_smart_contract do
    trait :address_1 do
      id                 { 1 }
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      address            { '0xbbd602bb278edff65cbc967b9b62095ad5be23a3' }
      state              { 'active' }
    end

    trait :address_2 do
      id                 { 2 }
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      address            { '0xe3cb6897d83691a8eb8458140a1941ce1d6e6dac' }
      state              { 'active' }
    end

    trait :address_3 do
      id                 { 3 }
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      address            { '0x4b6a630ff1f66604d31952bdce2e4950efc99821' }
      state              { 'active' }
    end

    trait :address_4 do
      id                 { 4 }
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      address            { '0xc4d276bf32b71cdddb18f3b4d258f057a5ffda03' }
      state              { 'active' }
    end

    trait :address_5 do
      id                 { 5 }
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      address            { '0x87099add3bcc0821b5b151307c147215f839a110' }
      state              { 'active' }
    end

    trait :address_6 do
      id                 { 6 }
      association :blockchain, 'eth-rinkeby', strategy: :find_or_create, key: 'eth-rinkeby'
      address            { '0xb4bb6260f4a5c76609e8f1cb62bf0a4a59dce729' }
      state              { 'active' }
    end
  end
end
