# frozen_string_literal: true

describe OrderServices::CreateOrder do
  let(:market) { Market.find_spot_by_symbol('btc_usd') }
  let(:service) { described_class.new(member: account.member) }
  let(:account) { create(:account, :usd, balance: 10.to_d) }
  let(:default_params) do
    {
      market: market,
      side: 'buy', # buy/sell
      volume: '1'.to_d,
      ord_type: 'market' # limit/market
    }
  end

  let!(:ask_orders) do
    create(:order_ask, :btc_usd, price: '200', volume: '10.0', state: :wait)
    create(:order_ask, :btc_usd, price: '102', volume: '10.0', state: :wait)
    create(:order_ask, :btc_usd, price: '101', volume: '10.0', state: :wait)
    create(:order_ask, :btc_usd, price: '100', volume: '10.0', state: :wait)
  end
  let!(:bid_orders) do
    create(:order_bid, :btc_usd, price: '200', volume: '10.0', state: :wait)
    create(:order_bid, :btc_usd, price: '102', volume: '10.0', state: :wait)
    create(:order_bid, :btc_usd, price: '101', volume: '10.0', state: :wait)
    create(:order_bid, :btc_usd, price: '100', volume: '10.0', state: :wait)
  end

  shared_examples 'creates an order without exceptions' do
    it 'creates an order' do
      result = nil
      expect do
        result = service.perform(**params)
      end.not_to raise_error
      expect(result).to be_successful
      expect(result.data).to be_a_kind_of(Order)
    end
  end

  describe '#perform' do
    context 'insufficient liquidity' do
      context 'buy btc' do
        let(:account) { create(:account, :usd, balance: 10_000_000.to_d) }
        let(:uuid) { UUID.generate }
        let(:ton_of_btc_params) do
          {
            market: market,
            side: 'buy', # buy/sell
            volume: '1000'.to_d,
            ord_type: 'market', # limit/market
            uuid: uuid
          }
        end

        it 'fails with error message and send error into amqp' do
          ::AMQP::Queue.expects(:enqueue_event).with(
            'private',
            account.member.uid,
            'order_error',
            {
              uuid: uuid,
              payload: 'market.order.insufficient_market_liquidity'
            }
          )
          result = service.perform(**ton_of_btc_params)

          expect(result).to be_failed
          expect(result.errors.first).to eq('market.order.insufficient_market_liquidity')
        end
      end
    end

    context 'wrong side value' do
      let(:wrong_side_params) do
        default_params.merge(
          side: 'foobar'
        )
      end

      it 'fails with error message' do
        result = service.perform(**wrong_side_params)

        expect(result).to be_failed
        expect(result.errors.first).to(
          match(/side = foobar. Possible side values:/)
        )
      end
    end

    describe 'sumbit order' do
      context 'not peatio market engine' do
        it 'calls order.trigger_third_party_creation' do
          Engine.any_instance.stubs(:peatio_engine?).returns(false)
          Order.any_instance.expects(:trigger_third_party_creation)
          result = service.perform(**default_params)

          expect(result).to be_successful
        end
      end

      it 'sends all needed notifications' do
        Order.any_instance.expects(:trigger_private_event)
        EventAPI.expects(:notify)
        AMQP::Queue.expects(:enqueue).with(
          :order_processor,
          any_parameters
        )
        service.perform(**default_params)
      end
    end

    context 'buy btc' do
      include_examples 'creates an order without exceptions' do
        let(:params) do
          default_params
        end
      end

      context 'limit price' do
        let(:limit_price_params) do
          default_params.merge(
            ord_type: 'limit',
            price: '10'.to_d
          )
        end

        include_examples 'creates an order without exceptions' do
          let(:params) do
            limit_price_params
          end
        end
      end
    end

    context 'sell btc' do
      let(:account) { create(:account, :btc, balance: 10.to_d) }
      let(:default_params) do
        {
          market: market,
          side: 'buy', # buy/sell
          volume: '1'.to_d,
          ord_type: 'market' # limit/market
        }
      end

      include_examples 'creates an order without exceptions' do
        let(:params) do
          default_params
        end
      end

      context 'limit price' do
        let(:limit_price_params) do
          default_params.merge(
            ord_type: 'limit',
            price: '15'.to_d
          )
        end

        include_examples 'creates an order without exceptions' do
          let(:params) do
            limit_price_params
          end
        end
      end
    end
  end
end
