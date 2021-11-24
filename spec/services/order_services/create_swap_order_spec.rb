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
      CurrencyServices::SwapPrice.any_instance.stubs(:price_in_base).returns(reference_price)
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

    context 'faild create order' do
      let(:params) do
        {
          from_currency: market.base,
          to_currency: market.quote,
          volume: '1'.to_d,
          price: reference_price
        }
      end

      before do
        OrderServices::CreateOrder.any_instance.stubs(:perform).returns(ServiceBase::Result.new(errors: ['err']))
      end

      it 'return errors' do
        result = nil

        expect do
          result = service.perform(**params)
        end.to change(SwapOrder, :count)
        expect(SwapOrder.last.state).to eq('cancel')
        expect(result).to be_failed
        expect(result.errors.first).to eq 'err'
      end
    end

    context 'outdated price' do
      let(:params) do
        {
          from_currency: market.base,
          to_currency: market.quote,
          volume: '1'.to_d,
          price: '102.1'.to_d
        }
      end

      it 'return errors' do
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.outdated_price'
      end
    end
  end
end
