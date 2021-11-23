# frozen_string_literal: true

FactoryBot.define do
  factory :swap_order_bid, class: 'SwapOrder' do
    member

    trait :btc_usd do
      before(:create) do |swap_order|
        swap_order.order = create(:order_bid, :btc_usd, price: swap_order.price, volume: swap_order.volume, origin_volume: '12.13', member: swap_order.member, trades_count: 1)
      end

      side { :sell }
      market { Market.find_spot_by_symbol(:btc_usd) }
      state { :wait }
      price { '1'.to_d }
      volume { '1'.to_d }
    end
  end

  factory :swap_order_ask, class: 'SwapOrder' do
    member

    trait :btc_usd do
      after(:create) do |swap_order|
        swap_order.order = create(:order_ask, :btc_usd, price: swap_order.price, volume: swap_order.volume, origin_volume: '12.13', member: swap_order.member, trades_count: 1)
      end

      side { :buy }
      market { Market.find_spot_by_symbol(:btc_usd) }
      state { :wait }
      price { '1'.to_d }
      volume { '1'.to_d }
    end
  end
end
