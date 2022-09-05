# frozen_string_literal: true

describe API::V2::Market::SwapOrders, type: :request, swap: true do
  let(:member) { create(:member, :level_3) }
  let(:level_0_member) { create(:member, :level_0) }
  let(:token) { jwt_for(member) }
  let(:level_0_member_token) { jwt_for(level_0_member) }
  let(:reference_price) { '10.001'.to_d }
  let(:swap_config) { Rails.application.config_for(:swap) }
  let(:order_limit) { swap_config['order_limit'] }
  let(:daily_limit) { swap_config['daily_limit'] }
  let(:weekly_limit) { swap_config['weekly_limit'] }

  before do
    OrderBid.stubs(:get_depth).returns([[reference_price, 1000.to_d]])
    OrderAsk.stubs(:get_depth).returns([[reference_price, 1000.to_d]])

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
    let(:market) { Market.find_spot_by_symbol(:btc_usd) }
    let(:default_params) do
      {
        from_currency: 'btc',
        to_currency: 'usd',
        request_currency: 'btc',
        request_volume: '12.13',
        price: reference_price
      }
    end

    context 'unauthorized' do
      before do
        Ability.stubs(:user_permissions).returns([])
      end

      it 'renders unauthorized error' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params
        expect(response).to have_http_status :forbidden
        expect(response).to include_api_error('user.ability.not_permitted')
      end
    end

    it 'creates a sell swap order on peatio engine' do
      member.get_account(:btc).update(balance: 100)

      expect do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params
        expect(response).to be_successful

        swap_order = SwapOrder.last
        expect(response_body['id']).to eq swap_order.id
      end.to change(OrderAsk, :count).by(1)
    end

    it 'creates a buy swap order' do
      member.get_account(:usd).update(balance: 100_000)
      AMQP::Queue.expects(:enqueue).with(:order_processor, is_a(Hash), is_a(Hash), nil)

      expect do
        api_post '/api/v2/market/swap_orders', token: token, params: { from_currency: 'usd', to_currency: 'btc', request_currency: 'usd', request_volume: reference_price, price: (1 / reference_price).round(8) }
        expect(response).to be_successful

        swap_order = SwapOrder.last

        expect(response_body['id']).to eq swap_order.id
      end.to change(OrderBid, :count).by(1)
    end

    context 'validate request params' do
      before do
        OrderServices::CreateSwapOrder.any_instance.expects(:perform).never
      end

      it 'validates missing params' do
        member.get_account(:usd).update(balance: 100_000)
        api_post '/api/v2/market/swap_orders', token: token
        expect(response).to have_http_status(:unprocessable_entity)

        # TODO: Grape validation transform swap_order to swaporder
        expect(response).to include_api_error('market.swaporder.missing_request_currency')
        expect(response).to include_api_error('market.swaporder.missing_request_volume')
        expect(response).to include_api_error('market.swaporder.missing_price')
      end

      it 'validates request volume positiveness' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ request_volume: '-1.1' })
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.non_positive_volume')
      end

      it 'validates request volume to be a number' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ request_volume: 'test' })
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.non_decimal_volume')
      end

      it 'validates price positiveness' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ price: '-1.1' })
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.non_positive_price')
      end

      it 'validates price to be a number' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ price: 'test' })
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.non_decimal_price')
      end
    end

    context 'service validation' do
      it 'validates volume greater than min_amount' do
        member.get_account(:btc).update(balance: 1)
        m = Market.find_spot_by_symbol(:btc_usd)
        m.update(min_amount: 1.0)
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ request_volume: '0.1' })

        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.order.invalid_volume_or_price')
      end

      it 'validates enough funds' do
        OrderAsk.expects(:create!).raises(::Account::AccountError)
        member.get_account(:btc).update(balance: 1)
        api_post '/api/v2/market/swap_orders', token: token, params: default_params
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.account.insufficient_balance')
      end

      it 'validates outdated price' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ price: reference_price * 1.2 }) # +20%
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.outdated_price')
      end

      it 'validate no currency price' do
        Currency.any_instance.stubs(:price).returns(nil)
        api_post '/api/v2/market/swap_orders', token: token, params: default_params
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.no_currency_price')
      end

      it 'validate order limit' do
        api_post '/api/v2/market/swap_orders', token: token, params: default_params.merge({ request_volume: order_limit + 1 })
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.reached_order_limit')
      end

      it 'validate daily limit' do
        SwapOrder.stubs(:daily_amount_for).returns(daily_limit)
        api_post '/api/v2/market/swap_orders', token: token, params: default_params
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.reached_daily_limit')
      end

      it 'validate weekly limit' do
        SwapOrder.stubs(:weekly_amount_for).returns(weekly_limit)
        api_post '/api/v2/market/swap_orders', token: token, params: default_params
        expect(response.code).to eq '422'
        expect(response).to include_api_error('market.swap_order.reached_weekly_limit')
      end
    end
  end
end
