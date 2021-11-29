# frozen_string_literal: true

describe OrderServices::CreateSwapOrder do
  let(:market) { Market.find_spot_by_symbol('btc_usd') }
  let(:account) { create(:account, :usd, balance: 10.to_d) }
  let(:reference_price) { 15.1.to_d }
  let(:service) { described_class.new(member: account.member) }
  let(:default_params) do
    {
      market: market,
      from_currency: market.base,
      to_currency: market.quote,
      volume: '1'.to_d
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
      CurrencyServices::SwapPrice.any_instance.stubs(:price).returns(reference_price)
      CurrencyServices::Price.any_instance.stubs(:call).returns(1)
    end

    context 'change btc to usd' do
      include_examples 'creates an swap order without exceptions' do
        let(:params) do
          {
            from_currency: market.base,
            to_currency: market.quote,
            volume: '1'.to_d,
            price: reference_price.to_d
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
            volume: '5'.to_d,
            price: (1 / reference_price).to_d
          }
        end
      end
    end

    context 'validation' do
      let(:swap_config) { Rails.application.config_for(:swap) }
      let(:daily_limit) { swap_config['daily_limit'] }
      let(:weekly_limit) { swap_config['weekly_limit'] }

      let(:params) do
        {
          from_currency: market.base,
          to_currency: market.quote,
          volume: '1'.to_d,
          price: reference_price
        }
      end

      it 'return outdated_price error' do
        result = service.perform(**params.merge(price: '102.1'.to_d))
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.outdated_price'
      end

      it 'returns no_unified_currency error' do
        CurrencyServices::SwapPrice.any_instance.stubs(:unified_currency).returns(nil)
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.no_unified_currency'
      end

      it 'returns no_unified_price error' do
        CurrencyServices::SwapPrice.any_instance.stubs(:unified_price).returns(nil)
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.no_unified_price'
      end

      it 'daily limit has been reached out' do
        SwapOrder.stubs(:daily_unified_total_amount_for).returns(daily_limit)
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.reached_daily_limit'
      end

      it 'weekly limit has been reached out' do
        SwapOrder.stubs(:weekly_unified_total_amount_for).returns(weekly_limit)
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.reached_weekly_limit'
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
