# frozen_string_literal: true

describe OrderServices::CreateOrder do
  let(:account) { create_account(:usd, balance: 100) }
  let(:market) { Market.find_spot_by_symbol('btcusd') }
  let(:service) { described_class.new(member: account.member) }

  describe '#perform' do
    let(:default_params) {
      {
        market: market,
        side: 'buy', # buy/sell
        volume: 1,
        ord_type: 'limit', # limit/market
        price: 5,
      }
    }

    it 'creates an order' do
      order = service.perform(**default_params)
      expect(order).to be_present
    end
  end
end
