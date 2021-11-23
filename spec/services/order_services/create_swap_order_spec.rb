# frozen_string_literal: true

describe OrderServices::CreateSwapOrder do
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

  before do
    Market.any_instance.stubs(:valid_swap_price?).returns(true)
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
    context 'buy btc' do
      include_examples 'creates an swap order without exceptions' do
        let(:params) do
          {
            market: market,
            side: 'buy',
            volume: '1'.to_d,
            price: '10'.to_d
          }
        end
      end
    end

    context 'sell btc' do
      include_examples 'creates an swap order without exceptions' do
        let(:params) do
          {
            market: market,
            side: 'sell',
            volume: '1'.to_d,
            price: '15'.to_d
          }
        end
      end
    end

    context 'faild create order' do
      let(:params) do
        {
          market: market,
          side: 'sell',
          volume: '1'.to_d,
          price: '15'.to_d
        }
      end

      before do
        OrderServices::CreateOrder.any_instance.stubs(:perform).returns(ServiceBase::Result.new(errors: ['err']))
      end

      it 'return errors' do
        result = nil
        expect do
          result = service.perform(**params)
        end.not_to change(SwapOrder, :count)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'err'
      end
    end

    context 'validation error' do
      let(:params) do
        {
          market: market,
          side: 'sell',
          volume: '1'.to_d,
          price: -1
        }
      end

      it 'return errors' do
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.invalid_volume_or_price'
      end
    end

    context 'outdated price' do
      let(:params) do
        {
          market: market,
          side: 'sell',
          volume: '1'.to_d,
          price: 102.1
        }
      end

      it 'return errors' do
        Market.any_instance.stubs(:valid_swap_price?).with(102.1).returns(false)
        result = service.perform(**params)
        expect(result).to be_failed
        expect(result.errors.first).to eq 'market.swap_order.outdated_price'
      end
    end
  end
end
