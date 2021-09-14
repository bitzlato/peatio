# encoding: UTF-8
# frozen_string_literal: true

describe API::V2::Public::TradingFees, type: :request do
  before(:each) { clear_redis }
  describe 'GET /trading_fees' do
    before do
      create(:trading_fee, maker: 0.0005, taker: 0.001, market_id: :btc_usd, group: 'vip-0')
      create(:trading_fee, maker: 0.0008, taker: 0.001, market_id: :any, group: 'vip-0')
      create(:trading_fee, maker: 0.001, taker: 0.0012, market_id: :btc_usd, group: :any)
      create(:trading_fee, maker: 0.001, taker: 0.0012, market_id: :btc_eth, market_type: 'qe', group: :any)
    end

    it 'returns all trading fees' do
      api_get '/api/v2/public/trading_fees'

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).length).to eq TradingFee.spot.count
    end

    it 'pagination' do
      api_get '/api/v2/public/trading_fees', params: { limit: 1 }
      expect(JSON.parse(response.body).length).to eq 1
    end

    it 'filters by market_id' do
      api_get '/api/v2/public/trading_fees', params: { market_id: 'btc_usd' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['market_id'] }).to all eq 'btc_usd'
      expect(result.length).to eq TradingFee.spot.where(market_id: 'btc_usd').count
    end

    it 'filters by group' do
      api_get '/api/v2/public/trading_fees', params: { group: 'vip-0' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['group'] }).to all eq 'vip-0'
      expect(result.length).to eq TradingFee.spot.where(group: 'vip-0').count
    end

    it 'filters by market_type' do
      api_get '/api/v2/public/trading_fees', params: { market_type: 'qe' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['market_type'] }).to all eq 'qe'
      expect(result.length).to eq TradingFee.qe.count
    end

    it 'capitalized fee group' do
      api_get '/api/v2/public/trading_fees', params: { group: 'Vip-0' }

      result = JSON.parse(response.body)
      expect(result.map { |r| r['group'] }).to all eq 'vip-0'
      expect(result.length).to eq TradingFee.where(group: 'vip-0').count
    end
  end
end
