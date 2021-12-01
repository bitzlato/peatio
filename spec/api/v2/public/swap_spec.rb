# frozen_string_literal: true

describe API::V2::Public::Swap, type: :request do
  describe 'GET /api/v2/public/markets/swap' do
    let(:market) { Market.find_spot_by_symbol('btc_usd') }

    it 'return swap price' do
      CurrencyServices::SwapPrice.any_instance.stubs(:price).returns(15.1.to_d)
      api_get '/api/v2/public/swap/price', params: { from_currency: market.base_unit, to_currency: market.quote_unit, volume: 1}

      expect(response.code).to eq '200'
      expect(response_body).to include_json({ price: '15.1' })
    end


    it 'return swap limits' do
      swap_config = Rails.application.config_for(:swap)
      api_get '/api/v2/public/swap/limits'

      expect(response.code).to eq '200'
      expect(response_body).to include_json({
        order_limit: swap_config['order_limit'],
        daily_limit: swap_config['daily_limit'],
        weekly_limit: swap_config['weekly_limit'],
      })
    end
  end
end
