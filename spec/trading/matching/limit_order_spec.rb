# frozen_string_literal: true

describe Matching::LimitOrder do
  context 'initialize' do
    it 'throws invalid order error for empty attributes' do
      expect do
        described_class.new(type: '', price: '', volume: '')
      end.to raise_error(Matching::OrderError)
    end

    it 'initializes market' do
      expect(Matching.mock_limit_order(type: :bid).market).to eq 'btc_usd'
    end
  end

  context 'crossed?' do
    it 'crosses at lower or equal price for bid order' do
      order = Matching.mock_limit_order(type: :bid, price: '10.0'.to_d)
      expect(order.crossed?('9.0'.to_d)).to be true
      expect(order.crossed?('10.0'.to_d)).to be true
      expect(order.crossed?('11.0'.to_d)).to be false
    end

    it 'crosses at higher or equal price for ask order' do
      order = Matching.mock_limit_order(type: :ask, price: '10.0'.to_d)
      expect(order.crossed?('9.0'.to_d)).to be false
      expect(order.crossed?('10.0'.to_d)).to be true
      expect(order.crossed?('11.0'.to_d)).to be true
    end
  end
end
