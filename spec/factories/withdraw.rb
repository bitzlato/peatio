# frozen_string_literal: true

# Legacy withdraw factories are deprecated because they update
# account balance in database without creating liability operation.
#
# Use new withdraw factories instead.
# You can create liability history by passing with_deposit_liability trait.
#
# TODO: Add new factories for all currencies.
FactoryBot.define do
  factory :btc_withdraw, class: 'Withdraws::Coin' do
    # We need to have valid Liability-based balance to spend funds.
    trait :with_deposit_liability do
      before(:create) do |withdraw|
        deposit = create(:deposit_btc, member: withdraw.member, amount: withdraw.sum)
        deposit.accept!
        deposit.process!
        deposit.dispatch!
      end
    end

    trait :with_beneficiary do
      beneficiary do
        create(:beneficiary, :btc,
               blockchain_currency: BlockchainCurrency.find_by!(blockchain: find_or_create(:blockchain, 'btc-testnet', key: 'btc-testnet'), currency_id: :btc),
               member: member,
               state: :active)
      end
      rid { nil }
    end

    blockchain { find_or_create(:blockchain, 'btc-testnet', key: 'btc-testnet') }
    currency { Currency.find(:btc) }
    member { create(:member, :level_3) }
    rid { Faker::Blockchain::Bitcoin.address }
    sum { 10.to_d }
    type { 'Withdraws::Coin' }
  end

  factory :btc_bz_withdraw, class: 'Withdraws::Coin' do
    trait :with_deposit_liability do
      before(:create) do |withdraw|
        deposit = create(:deposit_btc_bz, member: withdraw.member, amount: withdraw.sum)
        deposit.accept!
        deposit.process!
        deposit.dispatch!
      end
    end

    member { create(:member, :level_3) }
    rid { 'rid' }
    sum { 10.to_d }
    type { 'Withdraws::Coin' }
  end

  factory :eth_withdraw, class: 'Withdraws::Coin' do
    trait :with_deposit_liability do
      before(:create) do |withdraw|
        deposit = create(:deposit, :deposit_eth, member: withdraw.member, amount: withdraw.sum)
        deposit.accept!
        deposit.process!
        deposit.dispatch!
      end
    end

    blockchain { find_or_create(:blockchain, 'eth-rinkeby', key: 'eth-rinkeby') }
    currency { Currency.find(:eth) }
    member { create(:member, :level_3) }
    rid { Faker::Blockchain::Ethereum.address }
    sum { 10.to_d }
    type { 'Withdraws::Coin' }

    trait :with_beneficiary do
      beneficiary do
        create(:beneficiary,
               currency: currency,
               member: member,
               state: :active)
      end
      rid { nil }
    end
  end

  factory :usd_withdraw, class: 'Withdraws::Fiat' do
    # We need to have valid Liability-based balance to spend funds.
    trait :with_deposit_liability do
      before(:create) do |withdraw|
        create(:deposit_usd, member: withdraw.member, amount: withdraw.sum)
          .accept!
      end
    end

    trait :with_beneficiary do
      beneficiary do
        create(:beneficiary,
               blockchain_currency: BlockchainCurrency.find_by!(blockchain: find_or_create(:blockchain, 'dummy', key: 'dummy'), currency_id: :usd),
               member: member,
               state: :active)
      end
      rid { nil }
    end

    member { create(:member, :level_3) }
    blockchain { find_or_create(:blockchain, 'dummy', key: 'dummy') }
    currency { Currency.find(:usd) }
    rid { Faker::Bank.iban }
    sum { 1000.to_d }
    type { 'Withdraws::Fiat' }
  end
end
