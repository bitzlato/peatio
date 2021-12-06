# frozen_string_literal: true

FactoryBot.define do
  factory :swap_order_bid, class: 'SwapOrder' do
    member

    trait :btc_usd do
      before(:create) do |swap_order|
        swap_order.order = create(:order_bid, :btc_usd, price: swap_order.request_price, volume: '12.13', origin_volume: '12.13', member: swap_order.member, trades_count: 1)
      end

      market { Market.find_spot_by_symbol(:btc_usd) }
      from_currency { market.base }
      to_currency { market.quote }
      from_volume { '1'.to_d }
      to_volume { '1'.to_d }
      request_currency { market.base }
      request_price { '1'.to_d }
      request_volume { '1'.to_d }
      inverse_price { '1'.to_d }
      state { :wait }
    end
  end

  factory :swap_order_ask, class: 'SwapOrder' do
    member

    trait :btc_usd do
      after(:create) do |swap_order|
        swap_order.order = create(:order_ask, :btc_usd, price: swap_order.inverse_price, volume: '12.13', origin_volume: '12.13', member: swap_order.member, trades_count: 1)
      end

      market { Market.find_spot_by_symbol(:btc_usd) }

      from_currency { market.quote }
      to_currency { market.base }
      from_volume { '1'.to_d }
      to_volume { '1'.to_d }
      request_currency { market.base }
      request_price { '1'.to_d }
      request_volume { '1'.to_d }
      inverse_price { '1'.to_d }
      state { :wait }
    end
  end
end
