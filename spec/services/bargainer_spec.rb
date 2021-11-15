# frozen_string_literal: true

RSpec.describe Bargainer do
  subject(:service) { described_class.new }

  describe '#call' do
    it 'creates bargain' do
      market = find_or_create(:market, :btc_eth, symbol: :btc_eth)
      member = create(:member)
      create(:order_ask, :btc_eth, price: 5000)
      create(:order_bid, :btc_eth, price: 4900)
      service.call(market: market, member: member, min_volume: 0.0005, max_volume: 0.001, price_deviation: 0.001, arbitrage_max_spread: 0.022)
      expect(member.orders.count).to eq 2
    end
  end
end
