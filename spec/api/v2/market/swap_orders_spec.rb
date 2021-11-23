# frozen_string_literal: true

describe API::V2::Market::SwapOrders, type: :request do
  let(:member) { create(:member, :level_3) }
  let(:level_0_member) { create(:member, :level_0) }
  let(:token) { jwt_for(member) }
  let(:level_0_member_token) { jwt_for(level_0_member) }

  before do
    Market.any_instance.stubs(:valid_swap_price?).returns(true)
    Ability.stubs(:user_permissions).returns({ 'member' => { 'read' => ['SwapOrder'], 'create' => ['SwapOrder'], 'update' => ['SwapOrder'] } })
  end

  describe 'GET /api/v2/market/swap_orders/:id' do
    let!(:swap_order) { create :swap_order_bid, :btc_usd, member: member }

    it 'gets specified spot swap order by id' do
      api_get "/api/v2/market/swap_orders/#{swap_order.id}", token: token

      expect(response).to be_successful
      expect(response_body['id']).to eq swap_order.id
    end

    context 'unauthorized' do
      before do
        Ability.stubs(:user_permissions).returns([])
      end

      it 'renders unauthorized error' do
        api_get "/api/v2/market/swap_orders/#{swap_order.id}", token: token
        expect(response).to have_http_status :forbidden
        expect(response).to include_api_error('user.ability.not_permitted')
      end
    end

    it 'gets 404 error when order doesn\'t exist' do
      api_get '/api/v2/market/swap_orders/1234', token: token
      expect(response.code).to eq '404'
      expect(response).to include_api_error('record.not_found')
    end
  end

  describe 'POST /api/v2/market/swap_orders' do
    it 'creates a sell swap order on peatio engine' do
      member.get_account(:btc).update(balance: 100)

      expect do
        api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '12.13', price: '2014' }
        expect(response).to be_successful

        swap_order = SwapOrder.last
        expect(response_body['id']).to eq swap_order.id
      end.to change(OrderAsk, :count).by(1)
    end

    it 'creates a buy swap order' do
      member.get_account(:usd).update(balance: 100_000)
      AMQP::Queue.expects(:enqueue).with(:order_processor, is_a(Hash), is_a(Hash), nil)

      expect do
        api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'buy', volume: '12.13', price: '2014' }
        expect(response).to be_successful

        swap_order = SwapOrder.last
        expect(response_body['id']).to eq swap_order.id
      end.to change(OrderBid, :count).by(1)
    end

    context 'unauthorized' do
      before do
        Ability.stubs(:user_permissions).returns([])
      end

      it 'renders unauthorized error' do
        api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'buy', volume: '12.13', price: '2014' }
        expect(response).to have_http_status :forbidden
        expect(response).to include_api_error('user.ability.not_permitted')
      end
    end

    it 'validates missing params' do
      member.get_account(:usd).update(balance: 100_000)
      api_post '/api/v2/market/swap_orders', token: token
      expect(response).to have_http_status(:unprocessable_entity)

      # TODO: Grape validation transform swap_order to swaporder
      expect(response).to include_api_error('market.swaporder.missing_market')
      expect(response).to include_api_error('market.swaporder.missing_side')
      expect(response).to include_api_error('market.swaporder.missing_volume')
      expect(response).to include_api_error('market.swaporder.missing_price')
    end

    it 'validates volume positiveness' do
      old_count = OrderAsk.count
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '-1.1', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.non_positive_volume')
      expect(OrderAsk.count).to eq old_count
    end

    it 'validates volume to be a number' do
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: 'test', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.non_decimal_volume')
    end

    it 'validates volume greater than min_amount' do
      member.get_account(:btc).update(balance: 1)
      m = Market.find_spot_by_symbol(:btc_usd)
      m.update(min_amount: 1.0)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '0.1', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.invalid_volume_or_price')
    end

    it 'validates price less than max_price' do
      member.get_account(:usd).update(balance: 1)
      m = Market.find_spot_by_symbol(:btc_usd)
      m.update(max_price: 1.0)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'buy', volume: '0.1', price: '2' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.invalid_volume_or_price')
    end

    it 'validates volume precision' do
      member.get_account(:usd).update(balance: 1)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'buy', volume: '0.123456789', price: '0.1' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.invalid_volume_or_price')
    end

    it 'validates price greater than min_price' do
      member.get_account(:usd).update(balance: 1)
      m = Market.find_spot_by_symbol(:btc_usd)
      m.update(min_price: 1.0)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'buy', volume: '0.1', price: '0.2' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.invalid_volume_or_price')
    end

    it 'validates price precision' do
      member.get_account(:usd).update(balance: 1)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'buy', volume: '0.12', price: '0.123' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.invalid_volume_or_price')
    end

    it 'validates enough funds' do
      OrderAsk.expects(:create!).raises(::Account::AccountError)
      member.get_account(:btc).update(balance: 1)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '12.13', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.account.insufficient_balance')
    end

    it 'validates price positiveness' do
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '12.13', price: '-1.1' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.non_positive_price')
    end

    it 'validates price to be a number' do
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '12.13', price: 'test' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.non_decimal_price')
    end

    it 'validates outdated price' do
      Market.any_instance.stubs(:valid_swap_price?).with(102.1).returns(false)
      api_post '/api/v2/market/swap_orders', token: token, params: { market: 'btc_usd', side: 'sell', volume: '12.13', price: '102.1' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.outdated_price')
    end
  end
end
