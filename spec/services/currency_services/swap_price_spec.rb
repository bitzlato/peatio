# frozen_string_literal: true

RSpec.describe CurrencyServices::SwapPrice, swap: true do
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
    let(:price) { market.round_price(top_price - (top_price * deviation)) }
    let(:request_price) { price }
    let(:inverse_price) { (1 / price).round(8) }
    let(:request_volume) { 3 }
    let(:from_volume) { request_volume }
    let(:to_volume) { market.round_amount(request_volume * request_price) }

    context 'when volume_currency is from_currency' do
      subject do
        described_class.new(from_currency: from_currency, to_currency: to_currency,
                            request_currency: request_currency, request_volume: request_volume)
      end

      let(:request_currency) { from_currency }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('sell') }
      it { expect(subject.sell?).to be(true) }
      it { expect(subject.buy?).to be(false) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq(inverse_price) }

      it do
        expect(subject.valid_price?(request_price)).to eq(true)
        expect(subject.valid_price?(request_price * 1.2)).to eq(false) # +20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(from_currency.id) }
        it { expect(price_object.to_currency).to eq(to_currency.id) }
        it { expect(price_object.request_currency).to eq(from_currency.id) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price).to eq(price) }
        it { expect(price_object.inverse_price).to eq(inverse_price) }
        it { expect(price_object.from_volume).to eq(from_volume) }
        it { expect(price_object.to_volume).to eq(to_volume) }
      end
    end

    context 'when volume_currency is to_currency' do
      subject do
        described_class.new(from_currency: from_currency, to_currency: to_currency,
                            request_currency: request_currency, request_volume: request_volume)
      end

      let(:request_currency) { to_currency }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('sell') }
      it { expect(subject.sell?).to be(true) }
      it { expect(subject.buy?).to be(false) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq(inverse_price) }

      it do
        expect(subject.valid_price?(price)).to eq(true)
        expect(subject.valid_price?(price * 1.2)).to eq(false) # +20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(from_currency.id) }
        it { expect(price_object.to_currency).to eq(to_currency.id) }
        it { expect(price_object.request_currency).to eq(to_currency.id) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price).to eq(price) }
        it { expect(price_object.inverse_price).to eq(inverse_price) }
        it { expect(price_object.from_volume).to eq(market.round_amount(inverse_price * request_volume)) }
        it { expect(price_object.to_volume).to eq(request_volume) }
      end
    end
  end

  describe 'buy btc for usd' do
    let(:price) { market.round_price(top_price + (top_price * deviation)) }
    let(:inverse_price) { price }
    let(:request_price) { (1 / price).round(8) }
    let(:request_volume) { 20 }
    let(:volume) { market.round_amount(request_volume * request_price) }

    context 'when volume_currency is from_currency' do
      subject do
        described_class.new(from_currency: to_currency, to_currency: from_currency,
                            request_currency: request_currency, request_volume: request_volume)
      end

      let(:request_currency) { to_currency }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('buy') }
      it { expect(subject.sell?).to be(false) }
      it { expect(subject.buy?).to be(true) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq((1 / price).round(8)) }

      it do
        expect(subject.valid_price?(request_price)).to eq(true)
        expect(subject.valid_price?(request_price * 0.8)).to eq(false) # -20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(to_currency.id) }
        it { expect(price_object.to_currency).to eq(from_currency.id) }
        it { expect(price_object.request_currency).to eq(request_currency.id) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price).to eq(request_price) }
        it { expect(price_object.inverse_price).to eq(inverse_price) }
        it { expect(price_object.from_volume).to eq(request_volume) }
        it { expect(price_object.to_volume).to eq(volume) }
      end
    end

    context 'when volume_currency is to_currency' do
      subject do
        described_class.new(from_currency: to_currency, to_currency: from_currency,
                            request_currency: request_currency, request_volume: request_volume)
      end

      let(:request_currency) { from_currency }

      it { expect(subject.market).to eq(market) }
      it { expect(subject.market?).to be(true) }
      it { expect(subject.side).to eq('buy') }
      it { expect(subject.sell?).to be(false) }
      it { expect(subject.buy?).to be(true) }
      it { expect(subject.price).to eq(price) }
      it { expect(subject.inverse_price).to eq((1 / price).round(8)) }

      it do
        expect(subject.valid_price?(request_price)).to eq(true)
        expect(subject.valid_price?(request_price * 0.8)).to eq(false) # -20%
      end

      context 'price object' do
        let(:price_object) { subject.price_object }

        it { expect(price_object.from_currency).to eq(to_currency.id) }
        it { expect(price_object.to_currency).to eq(from_currency.id) }
        it { expect(price_object.request_currency).to eq(request_currency.id) }
        it { expect(price_object.request_volume).to eq(request_volume) }
        it { expect(price_object.request_price).to eq(request_price) }
        it { expect(price_object.inverse_price).to eq(inverse_price) }
        it { expect(price_object.from_volume).to eq(market.round_amount(request_volume * price)) }
        it { expect(price_object.to_volume).to eq(request_volume) }
      end
    end
  end
end
