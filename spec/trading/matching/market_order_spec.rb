# frozen_string_literal: true

describe Matching::MarketOrder do
  context 'initialize' do
    it 'does not allow price attribute' do
      expect { Matching.mock_market_order(type: :ask, price: '1.0'.to_d) }.to raise_error(Matching::OrderError)
    end

    it 'onlies accept positive sum limit' do
      expect { Matching.mock_market_order(type: :bid, locked: '0.0'.to_d) }.to raise_error(Matching::OrderError)
    end
  end

  describe '#fill' do
    subject { Matching.mock_market_order(type: :bid, locked: '10.0'.to_d, volume: '2.0'.to_d) }

    it 'raises not enough volume error' do
      expect { subject.fill('1.0'.to_d, '3.0'.to_d, '3.0'.to_d) }.to raise_error(Matching::NotEnoughVolume)
    end

    it 'raises sum limit reached error' do
      expect { subject.fill('11.0'.to_d, '1.0'.to_d, '11.0'.to_d) }.to raise_error(Matching::ExceedSumLimit)
    end

    it 'alsoes decrease volume and sum limit' do
      subject.fill '6.0'.to_d, '1.0'.to_d, '6.0'.to_d
      expect(subject.volume).to eq '1.0'.to_d
      expect(subject.locked).to eq '4.0'.to_d
    end
  end
end
