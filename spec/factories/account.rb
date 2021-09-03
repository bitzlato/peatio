# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    balance { 0.to_d }
    member
    currency_id { :usd }

    trait :usd do
      currency_id { :usd }
    end

    trait :btc do
      currency_id { :btc }
    end

    trait :eth do
      currency_id { :eth }
    end
  end
end
