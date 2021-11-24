# frozen_string_literal: true

describe API::V2::Public::Swap, type: :request do
  describe 'GET /api/v2/public/markets/swap' do
    let(:market) { Market.find_spot_by_symbol('btc_usd') }

    it 'return swap price' do
      Market.any_instance.stubs(:swap_price).returns(15.1)
      api_get '/api/v2/public/swap/price', params: { from_currency: market.base_unit, to_currency: market.quote_unit }

      expect(response.code).to eq '200'
      expect(response_body).to include_json({ price: 15.1 })
    end
  end
end