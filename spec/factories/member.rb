# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :member do
    email { Faker::Internet.email }
    level { 0 }
    uid { "ID#{Faker::Number.unique.hexadecimal(10)}".upcase }
    role { "member" }
    group { "vip-0" }
    state { "active" }

    trait :level_3 do
      level { 3 }
    end

    trait :level_2 do
      level { 2 }
    end

    trait :level_1 do
      level { 1 }
    end

    trait :level_0 do
      level { 0 }
    end

    trait :admin do
      role { "admin" }
    end

    trait :barong do
      level { 3 }
    end

    trait :with_usd_balance do
      accounts { [create(:account, :usd, balance: 10000.to_d)] }
    end

    trait :with_btc_balance do
      accounts { [create(:account, :btc, balance: 10000.to_d)] }
    end

    trait :with_eth_balance do
      accounts { [create(:account, :eth, balance: 10000.to_d)] }
    end

    factory :admin_member, traits: %i[admin]
  end
end
