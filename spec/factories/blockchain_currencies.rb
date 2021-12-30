# frozen_string_literal: true

FactoryBot.define do
  factory :blockchain_currency do
    blockchain factory: %i[blockchain eth-ropsten]
    currency factory: %i[currency usdt]
  end
end
