# # encoding: UTF-8
# # frozen_string_literal: true

# module AccountFactory
#   def create_account(*arguments)
#     currency   = Symbol === arguments.first ? arguments.first : :usd
#     attributes = arguments.extract_options!
#     attributes.delete(:member) { create(:member) }.get_account(currency).tap do |account|
#       account.update!(attributes)
#     end
#   end
# end

# RSpec.configure { |config| config.include AccountFactory }

# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    balance { 0.to_d }
    member

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
