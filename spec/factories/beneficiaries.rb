# frozen_string_literal: true

FactoryBot.define do
  sequence(:btc_beneficiary_data) do
    { address: Faker::Blockchain::Bitcoin.address }
  end

  sequence(:eth_beneficiary_data) do
    { address: Faker::Blockchain::Ethereum.address }
  end

  sequence(:fiat_beneficiary_data) do
    { full_name:                    Faker::Name.name_with_middle,
      address:                      Faker::Address.full_address,
      country:                      Faker::Address.country,
      account_number:               Faker::Bank.account_number,
      account_type:                 %w[saving checking money-market CDs retirement].sample,
      bank_name:                    Faker::Bank.name,
      bank_address:                 Faker::Address.full_address,
      bank_country:                 Faker::Address.country,
      bank_swift_code:              Faker::Bank.swift_bic,
      intermediary_bank_name:       Faker::Bank.name,
      intermediary_bank_address:    Faker::Address.full_address,
      intermediary_bank_country:    Faker::Address.country,
      intermediary_bank_swift_code: Faker::Bank.swift_bic }
  end

  factory :beneficiary do
    member { create(:member) }
    currency { Currency.all.sample }
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    state { 'pending' }

    data do
      # Use save navigation operator for cases when currency is nil.
      if currency&.coin?
        generate(:eth_beneficiary_data)
      elsif currency&.fiat?
        generate(:fiat_beneficiary_data).merge(currency: currency.id)
      end
    end

    trait :btc do
      data do
        generate(:btc_beneficiary_data)
      end
    end
  end
end
