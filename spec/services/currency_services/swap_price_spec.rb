# frozen_string_literal: true

RSpec.describe CurrencyServices::SwapPrice do
  let(:from_currency) { find_or_create(:currency, id: :btc) }
  let(:to_currency) { find_or_create(:currency, id: :usd) }
  let(:market) { Market.find_by(symbol: 'btc_usd') }
  let(:deviation) { 0.02 }
  let(:top_price) { 100.to_d * market.price_precision }

  before do
    OrderBid.stubs(:get_depth).returns([[top_price, 100.to_d]])
    OrderAsk.stubs(:get_depth).returns([[top_price, 100.to_d]])
  end

  context 'sale btc for usd' do
    let(:request_volume) { 3 }
    let(:price) { market.round_price(top_price - (top_price * deviation)) }
    let(:inverse_price) { (1 / price).round(8) }
    let(:volume) { market.round_amount(request_volume * price) }

    context 'when volume_currency is from_currency' do
      subject { described_class.new(from_currency: from_currency, to_currency: to_currency, volume_currency: from_currency, volume: request_volume) }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('sell') }
      it { expect(subject.sell?).to be(true) }
      it { expect(subject.buy?).to be(false) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq(inverse_price) }
      it do
        p = price - (price * deviation)
        expect(subject.valid_price?(p)).to eq(true)
        expect(subject.valid_price?(p * 1.2)).to eq(false) # +20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(from_currency) }
        it { expect(price_object.to_currency).to eq(to_currency) }
        it { expect(price_object.request_currency).to eq(from_currency) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price ).to eq(price) }
        it { expect(price_object.inverse_price ).to eq(inverse_price) }
        it { expect(price_object.from_volume ).to eq(request_volume) }
        it { expect(price_object.to_volume ).to eq(volume) }
      end
    end

    context 'when volume_currency is to_currency' do
      subject { described_class.new(from_currency: from_currency, to_currency: to_currency, volume_currency: to_currency, volume: request_volume) }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('sell') }
      it { expect(subject.sell?).to be(true) }
      it { expect(subject.buy?).to be(false) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq(inverse_price) }
      it do
        expect(subject.valid_price?(inverse_price)).to eq(true)
        expect(subject.valid_price?(inverse_price * 1.2)).to eq(false) # +20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(from_currency) }
        it { expect(price_object.to_currency).to eq(to_currency) }
        it { expect(price_object.request_currency).to eq(to_currency) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price ).to eq(inverse_price) }
        it { expect(price_object.inverse_price ).to eq(price) }
        it { expect(price_object.from_volume ).to eq(volume) }
        it { expect(price_object.to_volume).to eq(request_volume) }
      end
    end
  end

  describe 'buy btc for usd' do
    let(:request_volume) { 20 }
    let(:price) { market.round_price(top_price + (top_price * deviation)) }
    let(:inverse_price) {(1 / price).round(8) }
    let(:volume) { market.round_amount(request_volume * inverse_price) }

    context 'when volume_currency is from_currency' do
      subject { described_class.new(from_currency: to_currency, to_currency: from_currency, volume_currency: to_currency, volume: request_volume) }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('buy') }
      it { expect(subject.sell?).to be(false) }
      it { expect(subject.buy?).to be(true) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq(inverse_price) }
      it do
        p = inverse_price + (inverse_price * deviation)
        expect(subject.valid_price?(p)).to eq(true)
        expect(subject.valid_price?(p * 0.8)).to eq(false) # -20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(to_currency) }
        it { expect(price_object.to_currency).to eq(from_currency) }
        it { expect(price_object.request_currency).to eq(to_currency) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price ).to eq(inverse_price) }
        it { expect(price_object.inverse_price ).to eq(price) }
        it { expect(price_object.from_volume ).to eq(request_volume) }
        it { expect(price_object.to_volume ).to eq(volume) }
      end
    end

    context 'when volume_currency is to_currency' do
      subject { described_class.new(from_currency: to_currency, to_currency: from_currency, volume_currency: from_currency, volume: request_volume) }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('buy') }
      it { expect(subject.sell?).to be(false) }
      it { expect(subject.buy?).to be(true) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq(inverse_price) }
      it do
        expect(subject.valid_price?(price)).to eq(true)
        expect(subject.valid_price?(price * 0.8)).to eq(false) # -20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(to_currency) }
        it { expect(price_object.to_currency).to eq(from_currency) }
        it { expect(price_object.request_currency).to eq(from_currency) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price ).to eq(price) }
        it { expect(price_object.inverse_price ).to eq(inverse_price) }
        it { expect(price_object.from_volume ).to eq(volume) }
        it { expect(price_object.to_volume ).to eq(request_volume) }
      end
    end
  end
end
