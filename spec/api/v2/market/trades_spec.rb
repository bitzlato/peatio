# frozen_string_literal: true

describe API::V2::Market::Trades, type: :request do
  let(:member) do
    create(:member, :level_3).tap do |m|
      m.get_account(:btc).update_attributes(balance: 12.13,   locked: 3.14)
      m.get_account(:usd).update_attributes(balance: 2014.47, locked: 0)
    end
  end

  before do
    Ability.stubs(:user_permissions).returns({ 'member' => { 'read' => ['Trade'] } })
  end

  let(:token) { jwt_for(member) }

  let(:level_0_member) { create(:member, :level_0) }
  let(:level_0_member_token) { jwt_for(level_0_member) }

  let(:btc_usd_ask) do
    create(
      :order_ask,
      :btc_usd,
      price: '12.32'.to_d,
      volume: '123.12345678',
      member: member
    )
  end

  let(:btc_eth_ask) do
    create(
      :order_ask,
      :btc_eth,
      price: '12.32'.to_d,
      volume: '123.1234',
      member: member
    )
  end

  let(:btc_eth_qe_ask) do
    create(
      :order_ask,
      :btc_eth,
      price: '12.32'.to_d,
      volume: '123.1234',
      member: member
    )
  end

  let(:btc_usd_bid) do
    create(
      :order_bid,
      :btc_usd,
      price: '12.32'.to_d,
      volume: '123.12345678',
      member: member
    )
  end

  let(:btc_eth_bid) do
    create(
      :order_bid,
      :btc_eth,
      price: '12.32'.to_d,
      volume: '123.1234',
      member: member
    )
  end

  let(:btc_usd_bid_maker) do
    create(
      :order_bid,
      :btc_usd,
      price: '12.32'.to_d,
      volume: '123.12345678',
      member: member
    )
  end

  let(:btc_eth_ask_taker) do
    create(
      :order_ask,
      :btc_eth,
      price: '12.32'.to_d,
      volume: '123.1234',
      member: member
    )
  end

  let(:btc_eth_bid_taker) do
    create(
      :order_bid,
      :btc_eth,
      price: '12.32'.to_d,
      volume: '123.1234',
      member: member
    )
  end

  let(:btc_eth_qe_bid) do
    create(
      :order_bid,
      :btc_eth_qe,
      price: '12.32'.to_d,
      volume: '123.1234',
      member: member
    )
  end

  let!(:btc_usd_ask_trade) { create(:trade, :btc_usd, maker_order: btc_usd_ask, created_at: 2.days.ago) }
  let!(:btc_eth_ask_trade) { create(:trade, :btc_eth, maker_order: btc_eth_ask, created_at: 2.days.ago) }
  let!(:btc_eth_qe_ask_trade) { create(:trade, :btc_eth_qe, maker_order: btc_eth_qe_ask, created_at: 2.days.ago) }
  let!(:btc_usd_bid_trade) { create(:trade, :btc_usd, taker_order: btc_usd_bid, created_at: 23.hours.ago) }
  let!(:btc_eth_bid_trade) { create(:trade, :btc_eth, taker_order: btc_eth_bid, taker: member, created_at: 23.hours.ago) }
  let!(:btc_eth_qe_bid_trade) { create(:trade, :btc_eth_qe, taker_order: btc_eth_qe_bid, taker: member, created_at: 23.hours.ago) }

  describe 'GET /api/v2/market/trades' do
    it 'requires authentication' do
      get '/api/v2/market/trades', params: { market: 'btc_usd' }
      expect(response.code).to eq '401'
      expect(response).to include_api_error('jwt.decode_and_verify')
    end

    it 'returns all my recent spot trades' do
      api_get '/api/v2/market/trades', token: token
      expect(response).to be_successful

      result = JSON.parse(response.body)

      expect(result.size).to eq 4

      expect(result.find { |t| t['id'] == btc_usd_ask_trade.id }['side']).to eq 'sell'
      expect(result.find { |t| t['id'] == btc_usd_ask_trade.id }['order_id']).to eq btc_usd_ask.id
      expect(result.find { |t| t['id'] == btc_eth_ask_trade.id }['side']).to eq 'sell'
      expect(result.find { |t| t['id'] == btc_eth_ask_trade.id }['order_id']).to eq btc_eth_ask.id
      expect(result.find { |t| t['id'] == btc_usd_bid_trade.id }['side']).to eq 'buy'
      expect(result.find { |t| t['id'] == btc_usd_bid_trade.id }['order_id']).to eq btc_usd_bid.id
      expect(result.find { |t| t['id'] == btc_eth_bid_trade.id }['side']).to eq 'buy'
      expect(result.find { |t| t['id'] == btc_eth_bid_trade.id }['order_id']).to eq btc_eth_bid.id
    end

    it 'returns all my recent spot trades for btc_usd market' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: token
      expect(response).to be_successful

      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(result.find { |t| t['id'] == btc_usd_ask_trade.id }['side']).to eq 'sell'
      expect(result.find { |t| t['id'] == btc_usd_ask_trade.id }['order_id']).to eq btc_usd_ask.id
      expect(result.find { |t| t['id'] == btc_usd_bid_trade.id }['side']).to eq 'buy'
      expect(result.find { |t| t['id'] == btc_usd_bid_trade.id }['order_id']).to eq btc_usd_bid.id
    end

    it 'returns all my recent spot trades for btc_eth market' do
      api_get '/api/v2/market/trades', params: { market: 'btc_eth' }, token: token
      expect(response).to be_successful

      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(result.find { |t| t['id'] == btc_eth_ask_trade.id }['side']).to eq 'sell'
      expect(result.find { |t| t['id'] == btc_eth_ask_trade.id }['order_id']).to eq btc_eth_ask.id
      expect(result.find { |t| t['id'] == btc_eth_bid_trade.id }['side']).to eq 'buy'
      expect(result.find { |t| t['id'] == btc_eth_bid_trade.id }['order_id']).to eq btc_eth_bid.id
    end

    it 'returns all my recent qe trades for btc_eth market' do
      api_get '/api/v2/market/trades', params: { market: 'btc_eth', market_type: 'qe' }, token: token
      expect(response).to be_successful

      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(result.find { |t| t['id'] == btc_eth_qe_ask_trade.id }['side']).to eq 'sell'
      expect(result.find { |t| t['id'] == btc_eth_qe_ask_trade.id }['order_id']).to eq btc_eth_qe_ask.id
      expect(result.find { |t| t['id'] == btc_eth_qe_ask_trade.id }['market_type']).to eq 'qe'
      expect(result.find { |t| t['id'] == btc_eth_qe_bid_trade.id }['side']).to eq 'buy'
      expect(result.find { |t| t['id'] == btc_eth_qe_bid_trade.id }['order_id']).to eq btc_eth_qe_bid.id
      expect(result.find { |t| t['id'] == btc_eth_qe_bid_trade.id }['market_type']).to eq 'qe'
    end

    it 'returns trades for several markets' do
      api_get '/api/v2/market/trades', params: { market: %w[btc_usd btc_eth] }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result.size).to eq 4
    end

    it 'returns 1 trade' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd', limit: 1 }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result.size).to eq 1
    end

    it 'returns trades for last 24h' do
      create(:trade, :btc_usd, maker: member, created_at: 6.hours.ago)
      api_get '/api/v2/market/trades', params: { time_from: 1.day.ago.to_i }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result.size).to eq 3
    end

    it 'returns trades older than 1 day' do
      api_get '/api/v2/market/trades', params: { time_to: 1.day.ago.to_i }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result.size).to eq 2
    end

    it 'returns trades for specific hour' do
      create(:trade, :btc_usd, maker: member, created_at: 6.hours.ago)
      api_get '/api/v2/market/trades', params: { time_from: 7.hours.ago.to_i, time_to: 5.hours.ago.to_i }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result.size).to eq 1
    end

    it 'returns limit out of range error' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd', limit: 1024 }, token: token

      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.trade.invalid_limit')
    end

    it 'denies access to unverified member' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: level_0_member_token
      expect(response.code).to eq '403'
      expect(response).to include_api_error('market.trade.not_permitted')
    end

    it 'fee calculation for buy order' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: token
      result = JSON.parse(response.body).find { |t| t['side'] == 'buy' }

      expect(result['order_id']).to eq btc_usd_bid.id
      expect(result['fee_amount']).to eq((btc_usd_bid.taker_fee * btc_usd_bid_trade.amount).to_s)
      expect(result['fee']).to eq btc_usd_bid.taker_fee.to_s
    end

    it 'fee calculation for sell order' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: token
      result = JSON.parse(response.body).find { |t| t['side'] == 'sell' }

      expect(result['order_id']).to eq btc_usd_ask.id
      expect(result['fee_amount']).to eq((btc_usd_ask.taker_fee * btc_usd_ask_trade.total).to_s)
      expect(result['fee']).to eq btc_usd_ask.taker_fee.to_s
    end

    it 'fee currency for buy order' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: token
      result = JSON.parse(response.body).find { |t| t['side'] == 'buy' }

      expect(result['order_id']).to eq btc_usd_bid.id
      expect(result['fee_currency']).to eq 'btc'
    end

    it 'fee currency for sell order' do
      api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: token
      result = JSON.parse(response.body).find { |t| t['side'] == 'sell' }

      expect(result['order_id']).to eq btc_usd_ask.id
      expect(result['fee_currency']).to eq 'usd'
    end

    context 'type filtering' do
      context 'sell orders' do
        let!(:btc_eth_ask_trade_taker) { create(:trade, :btc_eth, taker_order: btc_eth_ask_taker, created_at: 2.hours.ago) }
        let!(:btc_usd_bid_trade_maker) { create(:trade, :btc_usd, maker_order: btc_usd_bid_maker, created_at: 2.hours.ago) }

        it 'with taker_id = user_id and taker_type = sell' do
          api_get '/api/v2/market/trades', params: { market: 'btc_eth', type: 'sell' }, token: token
          result = JSON.parse(response.body)

          expect(result.size).to eq 2
          expect(result.find { |t| t['id'] == btc_eth_ask_trade.id }['side']).to eq 'sell'
          expect(result.find { |t| t['id'] == btc_eth_ask_trade.id }['order_id']).to eq btc_eth_ask.id
          expect(result.find { |t| t['id'] == btc_eth_ask_trade_taker.id }['side']).to eq 'sell'
          expect(result.find { |t| t['id'] == btc_eth_ask_trade_taker.id }['order_id']).to eq btc_eth_ask_taker.id
        end

        it 'with maker_id = user_id and taker_type = buy' do
          api_get '/api/v2/market/trades', params: { market: 'btc_usd', type: 'sell' }, token: token
          result = JSON.parse(response.body)

          expect(result.size).to eq 2
          expect(result.find { |t| t['id'] == btc_usd_ask_trade.id }['side']).to eq 'sell'
          expect(result.find { |t| t['id'] == btc_usd_ask_trade.id }['order_id']).to eq btc_usd_ask.id
          expect(result.find { |t| t['id'] == btc_usd_bid_trade_maker.id }['side']).to eq 'buy'
          expect(result.find { |t| t['id'] == btc_usd_bid_trade_maker.id }['order_id']).to eq btc_usd_bid_maker.id
        end
      end

      context 'buy orders' do
        let!(:btc_eth_bid_trade_taker) { create(:trade, :btc_eth, taker_order: btc_eth_bid_taker, created_at: 2.hours.ago) }

        it 'with taker_id = user_id and taker_type = buy' do
          api_get '/api/v2/market/trades', params: { market: 'btc_eth', type: 'buy' }, token: token
          result = JSON.parse(response.body)

          expect(result.size).to eq 2
          expect(result.find { |t| t['id'] == btc_eth_bid_trade.id }['side']).to eq 'buy'
          expect(result.find { |t| t['id'] == btc_eth_bid_trade.id }['order_id']).to eq btc_eth_bid.id
          expect(result.find { |t| t['id'] == btc_eth_bid_trade_taker.id }['side']).to eq 'buy'
          expect(result.find { |t| t['id'] == btc_eth_bid_trade_taker.id }['order_id']).to eq btc_eth_bid_taker.id
        end

        it 'with maker_id = user_id and taker_type = sell' do
          api_get '/api/v2/market/trades', params: { market: 'btc_usd', type: 'buy' }, token: token
          result = JSON.parse(response.body)

          expect(result.size).to eq 1
          expect(result.find { |t| t['id'] == btc_usd_bid_trade.id }['side']).to eq 'buy'
          expect(result.find { |t| t['id'] == btc_usd_bid_trade.id }['order_id']).to eq btc_usd_bid.id
        end
      end
    end

    context 'unauthorized' do
      before do
        Ability.stubs(:user_permissions).returns([])
      end

      it 'renders unauthorized error' do
        api_get '/api/v2/market/trades', params: { market: 'btc_usd' }, token: token
        expect(response).to have_http_status 403
        expect(response).to include_api_error('user.ability.not_permitted')
      end
    end
  end
end
