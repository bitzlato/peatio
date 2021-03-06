# frozen_string_literal: true

FactoryBot.define do
  factory :order_bid do
    member
    uuid { UUID.generate }

    # Create liability history by passing with_deposit_liability trait.
    trait :with_deposit_liability do
      before(:create) do |order|
        deposit = create(:deposit_usd, member: order.member, amount: order.locked)
        deposit.accept!
        deposit.process!
        deposit.dispatch!
      end

      bid { :usd }
      ask { :btc }
      market { Market.find_spot_by_symbol(:btc_usd) }
      market_type { 'spot' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { price.to_d * volume.to_d }
      origin_locked { locked.to_d }
    end

    trait :btc_usd do
      bid { :usd }
      ask { :btc }
      market { Market.find_spot_by_symbol(:btc_usd) }
      market_type { 'spot' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { price.to_d * volume.to_d }
      origin_locked { locked.to_d }
    end

    trait :btc_eth do
      bid { :eth }
      ask { :btc }
      market { Market.find_spot_by_symbol(:btc_eth) }
      market_type { 'spot' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { price.to_d * volume.to_d }
      origin_locked { locked.to_d }
    end

    trait :btc_eth_qe do
      bid { :eth }
      ask { :btc }
      market { Market.find_qe_by_symbol(:btc_eth) }
      market_type { 'qe' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { price.to_d * volume.to_d }
      origin_locked { locked.to_d }
    end
  end

  factory :order_ask do
    member
    uuid { UUID.generate }

    # Create liability history by passing with_deposit_liability trait.
    trait :with_deposit_liability do
      before(:create) do |order|
        deposit = create(:deposit_btc, member: order.member, amount: order.locked)
        deposit.accept!
        deposit.process!
        deposit.dispatch!
      end

      bid { :usd }
      ask { :btc }
      market { Market.find_spot_by_symbol(:btc_usd) }
      market_type { 'spot' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { volume.to_d }
      origin_locked { locked.to_d }
    end

    trait :btc_usd do
      bid { :usd }
      ask { :btc }
      market { Market.find_spot_by_symbol(:btc_usd) }
      market_type { 'spot' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { volume.to_d }
      origin_locked { locked.to_d }
    end

    trait :btc_eth do
      bid { :eth }
      ask { :btc }
      market { Market.find_spot_by_symbol(:btc_eth) }
      market_type { 'spot' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { volume.to_d }
      origin_locked { locked.to_d }
    end

    trait :btc_eth_qe do
      bid { :eth }
      ask { :btc }
      market { Market.find_qe_by_symbol(:btc_eth) }
      market_type { 'qe' }
      state { :wait }
      ord_type { 'limit' }
      price { '1'.to_d }
      volume { '1'.to_d }
      origin_volume { volume.to_d }
      locked { volume.to_d }
      origin_locked { locked.to_d }
    end
  end
end
