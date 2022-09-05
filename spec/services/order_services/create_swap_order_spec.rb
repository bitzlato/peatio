# frozen_string_literal: true

describe OrderServices::CreateSwapOrder, swap: true do
  let(:market) { Market.find_spot_by_symbol('btc_usd') }
  let(:account) { create(:account, :usd, balance: 10.to_d) }
  let(:reference_price) { 15.0075.to_d }
  let(:member) { account.member }
  let(:service) { described_class.new(member: member) }
  let(:default_params) do
    {
      from_currency: market.base,
      to_currency: market.quote,
      request_currency: market.base,
      request_volume: '1'.to_d,
      price: reference_price
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

  shared_examples 'creates an swap order without exceptions' do
    it 'creates an swap order and limit order' do
      result = nil
      expect do
        result = service.perform(**params)
      end.not_to raise_error
      expect(result).to be_successful
      expect(result.data).to be_a_kind_of(SwapOrder)
      expect(result.data.order).to be_present
      expect(result.data.order).to be_ord_type
    end
  end

  describe '#perform' do
    before do
      OrderBid.stubs(:get_depth).returns([[reference_price, 1000.to_d]])
      OrderAsk.stubs(:get_depth).returns([[reference_price, 1000.to_d]])
    end

    context 'change btc to usd' do
      include_examples 'creates an swap order without exceptions' do
        let(:params) do
          {
            from_currency: market.base,
            to_currency: market.quote,
            request_currency: market.base,
            request_volume: '1'.to_d,
            price: reference_price
          }
        end
      end
    end

    context 'change usd to btc' do
      include_examples 'creates an swap order without exceptions' do
        let(:params) do
          {
            from_currency: market.quote,
            to_currency: market.base,
            request_currency: market.base,
            request_volume: '1'.to_d,
            price: (1 / reference_price)
          }
        end
      end
    end

    context 'validation' do
      let(:swap_config) { Rails.application.config_for(:swap) }
      let(:order_limit) { swap_config['order_limit'] }
      let(:daily_limit) { swap_config['daily_limit'] }
      let(:weekly_limit) { swap_config['weekly_limit'] }

      let(:params) do
        {
          from_currency: market.base,
          to_currency: market.quote,
          request_currency: market.base,
          request_volume: '1'.to_d,
          price: reference_price
        }
      end

      it 'return outdated_price error' do
        result = service.perform(**params.merge(price: '102.1'.to_d))
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.outdated_price'
      end

      it 'returns no_currency_price error' do
        Currency.any_instance.stubs(:price).returns(nil)
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.no_currency_price'
      end

      it 'order limit has been reached out' do
        result = service.perform(**params.merge({ request_volume: order_limit + 1 }))
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.reached_order_limit'
      end

      it 'daily limit has been reached out' do
        create :swap_order_bid, :btc_usd, member: member, request_volume: daily_limit

        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.reached_daily_limit'
      end

      it 'weekly limit has been reached out' do
        date = Date.current.end_of_week
        Timecop.freeze(date) do
          create :swap_order_bid, :btc_usd, member: member, request_volume: weekly_limit, created_at: DateTime.yesterday

          result = service.perform(**params)
          expect(result).to be_failed
          expect(result.errors.first).to eq 'market.swap_order.reached_weekly_limit'
        end
      end

      it 'return error from CreateOrder service' do
        OrderServices::CreateOrder.any_instance.stubs(:perform).returns(ServiceBase::Result.new(errors: ['err']))
        result = nil
        expect do
          result = service.perform(**params)
        end.to change(SwapOrder, :count)
        expect(SwapOrder.last.state).to eq('cancel')
        expect(result).to be_failed
        expect(result.errors.first).to eq 'err'
      end
    end
  end
end
