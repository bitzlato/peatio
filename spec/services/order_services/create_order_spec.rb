# frozen_string_literal: true

describe OrderServices::CreateOrder do
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

  shared_examples 'creates an order without exceptions' do
    it 'creates an order' do
      order = nil
      expect {
        order = service.perform(**params)
      }.not_to raise_error
      expect(order).to be_present
    end
  end

  describe '#perform' do
    context 'insufficient liquidity' do
      context 'buy btc' do
        let(:account) { create(:account, :usd, balance: 10000000.to_d) }
        let(:ton_of_btc_params) {
          {
            market: market,
            side: 'buy', # buy/sell
            volume: '1000'.to_d,
            ord_type: 'market', # limit/market
          }
        }

        it 'return nil and send error into amqp' do
          ::AMQP::Queue.expects(:enqueue_event).with(
            'private',
            account.member.uid,
            'order_error',
            'market.order.insufficient_market_liquidity',
          )
          order = service.perform(**ton_of_btc_params)
          expect(order).to be_nil
        end
      end
    end

    context 'buy btc' do
      let(:account) { create(:account, :usd, balance: 10.to_d) }
      let(:default_params) {
        {
          market: market,
          side: 'buy', # buy/sell
          volume: '1'.to_d,
          ord_type: 'market', # limit/market
        }
      }

      include_examples 'creates an order without exceptions' do
        let(:params) {
          default_params
        }
      end

      context 'limit price' do
        let(:limit_price_params) {
          default_params.merge(
            ord_type: 'limit',
            price: '10'.to_d,
          )
        }

        include_examples 'creates an order without exceptions' do
          let(:params) {
            limit_price_params
          }
        end
      end
    end

    context 'sell btc' do
      let(:account) { create(:account, :btc, balance: 10.to_d) }
      let(:default_params) {
        {
          market: market,
          side: 'buy', # buy/sell
          volume: '1'.to_d,
          ord_type: 'market', # limit/market
        }
      }

      include_examples 'creates an order without exceptions' do
        let(:params) {
          default_params
        }
      end

      context 'limit price' do
        let(:limit_price_params) {
          default_params.merge(
            ord_type: 'limit',
            price: '15'.to_d,
          )
        }

        include_examples 'creates an order without exceptions' do
          let(:params) {
            limit_price_params
          }
        end
      end
    end
  end
end
