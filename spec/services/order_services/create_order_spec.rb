# frozen_string_literal: true

describe OrderServices::CreateOrder do
  let(:account) { create_account(:usd, balance: 10.to_d) }
  let(:market) { Market.find_spot_by_symbol('btcusd') }
  let(:service) { described_class.new(member: account.member) }

  let!(:ask_orders) do
    create(:order_ask, :btcusd, price: '200', volume: '10.0', state: :wait)
    create(:order_ask, :btcusd, price: '102', volume: '10.0', state: :wait)
    create(:order_ask, :btcusd, price: '101', volume: '10.0', state: :wait)
    create(:order_ask, :btcusd, price: '100', volume: '10.0', state: :wait)
  end
  let!(:bid_orders) do
    create(:order_bid, :btcusd, price: '200', volume: '10.0', state: :wait)
    create(:order_bid, :btcusd, price: '102', volume: '10.0', state: :wait)
    create(:order_bid, :btcusd, price: '101', volume: '10.0', state: :wait)
    create(:order_bid, :btcusd, price: '100', volume: '10.0', state: :wait)
  end

  describe '#perform' do
    let(:default_params) {
      {
        market: market,
        side: 'buy', # buy/sell
        volume: '1'.to_d,
        ord_type: 'market', # limit/market
      }
    }

    context 'limit price' do
      let(:limit_price_params) {
        default_params.merge(
          ord_type: 'limit',
          price: '15'.to_d,
        )
      }

      it 'creates an order' do
        order = service.perform(**limit_price_params)
        expect(order).to be_present
      end

      it 'processes without exceptions' do
        expect { service.perform(**limit_price_params) }.not_to raise_error
      end

    end

    it 'creates an order' do
      #puts OrderAsk.get_depth(market.symbol).inspect
      order = service.perform(**default_params)
      expect(order).to be_present
    end

    it 'processes without exceptions' do
      expect { service.perform(**default_params) }.not_to raise_error
    end

    # context 'out of balance' do
    #   before do
    #     # account.sub_funds!(960)
    #   end

    #   it 'raises Account::AccountError' do
    #     expect {
    #       service.perform(**default_params)
    #     }.to raise_error(
    #       Account::AccountError,
    #       "member_balance > locked = 3 > 5"
    #     )
    #   end
    # end
  end
end
