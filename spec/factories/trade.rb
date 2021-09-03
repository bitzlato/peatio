# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  factory :trade do
    trait :btc_usd do
      price { '10.0'.to_d }
      amount { '1.0'.to_d }
      total { price.to_d * amount.to_d }
      market { Market.find_spot_by_symbol(:btc_usd) }
      market_type { 'spot' }
      maker_order { create(:order_ask, :btc_usd) }
      taker_order { create(:order_bid, :btc_usd) }
      maker { maker_order.member }
      taker { taker_order.member }
    end

    trait :btc_eth do
      price { '10.0'.to_d }
      amount { '1.0'.to_d }
      total { price.to_d * amount.to_d }
      market { Market.find_spot_by_symbol(:btc_eth) }
      market_type { 'spot' }
      maker_order { create(:order_ask, :btc_eth) }
      taker_order { create(:order_bid, :btc_eth) }
      maker { maker_order.member }
      taker { taker_order.member }
    end

    trait :btc_eth_qe do
      price { '10.0'.to_d }
      amount { '1.0'.to_d }
      total { price.to_d * amount.to_d }
      market { Market.find_spot_by_symbol(:btc_eth) }
      market_type { 'qe' }
      maker_order { create(:order_ask, :btc_eth_qe) }
      taker_order { create(:order_bid, :btc_eth_qe) }
      maker { maker_order.member }
      taker { taker_order.member }
    end

    # Create liability history for orders by passing with_deposit_liability trait.
    trait :with_deposit_liability do
      maker_order { create(:order_ask, :with_deposit_liability) }
      taker_order { create(:order_bid, :with_deposit_liability) }
    end
  end
end
