# frozen_string_literal: true

describe API::V2::Market::SwapOrders, type: :request do
  let(:member) { create(:member, :level_3) }
  let(:level_0_member) { create(:member, :level_0) }
  let(:token) { jwt_for(member) }
  let(:level_0_member_token) { jwt_for(level_0_member) }

  before do
    Ability.stubs(:user_permissions).returns({ 'member' => { 'read' => ['SwapOrder'], 'create' => ['SwapOrder'], 'update' => ['SwapOrder'] } })
  end

  describe 'GET /api/v2/market/swap_orders/:id' do
    let!(:swap_order) { create :swap_order_bid, :btc_usd, member: member }

    it 'gets specified spot swap order by id' do
      api_get "/api/v2/market/swap_orders/#{swap_order.id}", token: token

      expect(response).to be_successful
      expect(response_body['id']).to eq swap_order.id
    end

    it 'gets specified swap order by uuid' do
      api_get "/api/v2/market/swap_orders/#{swap_order.uuid}", token: token

      expect(response).to be_successful
      expect(response_body['uuid']).to eq swap_order.uuid
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

    it 'raises error' do
      api_get '/api/v2/market/swap_orders/1234asd', token: token
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.swap_order.invaild_id_or_uuid')
    end
  end
end
