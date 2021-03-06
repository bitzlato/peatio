# frozen_string_literal: true

describe Matching::OrderBookManager do
  describe '.build_order' do
    it 'builds limit order' do
      order = ::Matching::OrderBookManager.build_order id: 1, market: 'btc_usd', ord_type: 'limit', type: 'ask', price: '1.0', volume: '1.0', timestamp: 12_345
      expect(order).to be_instance_of(::Matching::LimitOrder)
    end
  end
end
