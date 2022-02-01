# frozen_string_literal: true

FactoryBot.define do
  sequence :member_transfer_key do
    "member_transfer_#{Faker::Number.unique.number(5).to_i}"
  end

  factory :member_transfer do
    key { generate(:transfer_key) }
    service { MemberTransfer::AVAILABLE_SERVICES.sample }
    description { "#{service} for #{Time.now.to_date}" }
    currency { Currency.find(:btc) }
    member { create(:member, :level_3) }
    meta { { key: key } }

    trait :income do
      amount { 1 }
      after(:create) do |tm|
        create(:asset, reference: tm, credit: tm.amount)
        create(:liability, reference: tm, member: tm.member, credit: tm.amount)
      end
    end

    trait :outcome do
      amount { -1 }

      after(:create) do |tm|
        create(:asset, reference: tm, debit: tm.amount)
        create(:liability, reference: tm, member: tm.member, debit: tm.amount)
      end
    end

    factory :member_transfer_income, traits: %i[income]
    factory :member_transfer_outcome, traits: %i[outcome]
  end
end
