# frozen_string_literal: true

RSpec.describe CurrencyServices::SwapPrice do
  let(:from_currency) { find_or_create(:currency, id: :btc) }
  let(:to_currency) { find_or_create(:currency, id: :usd) }
  let(:market) { Market.find_by(symbol: 'btc_usd') }
  let(:deviation) { CurrencyServices::SwapPrice::PRICE_DEVIATION }

  context 'sale btc for usd' do
    subject { described_class.new(from_currency: from_currency, to_currency: to_currency) }

    let(:bid_top_price) { '100'.to_d }
    let(:price) { market.round_price(bid_top_price - (bid_top_price * deviation)) }
    let(:inverse_price) { (1 / price).to_d.round(CurrencyServices::SwapPrice::QUOTE_PRICE_PRECISION) }

    before { OrderBid.stubs(:top_price).returns(bid_top_price) }

    it { expect(subject.market).to eq(market) }
    it { expect(subject.market?).to be(true) }
    it { expect(subject.side).to eq('sell') }
    it { expect(subject.sell?).to be(true) }
    it { expect(subject.buy?).to be(false) }
    it { expect(subject.price).to eq(price) }
    it { expect(subject.inverse_price).to eq(inverse_price) }
    it { expect(subject.request_price).to eq(price) }

    it do
      p = price - (price * deviation)
      expect(subject.valid_price?(p)).to eq(true)
    end

    it do
      request_amount = generate_decimal(market.amount_precision + 1)
      base_amount = market.round_amount(request_amount)
      expect(subject.conver_amount_to_base(request_amount)).to eq(base_amount)
    end
  end

  context 'buy btc for usd' do
    subject { described_class.new(from_currency: to_currency, to_currency: from_currency) }

    let(:ask_top_price) { '120'.to_d }
    let(:price) { market.round_price(ask_top_price + (ask_top_price * deviation)) }
    let(:inverse_price) { (1 / price).to_d.round(CurrencyServices::SwapPrice::QUOTE_PRICE_PRECISION) }

    before { OrderAsk.stubs(:top_price).returns(ask_top_price) }

    it { expect(subject.market).to eq(market) }
    it { expect(subject.market?).to be(true) }
    it { expect(subject.side).to eq('buy') }
    it { expect(subject.sell?).to be(false) }
    it { expect(subject.buy?).to be(true) }
    it { expect(subject.price).to eq(price) }
    it { expect(subject.inverse_price).to eq(inverse_price) }
    it { expect(subject.request_price).to eq(inverse_price) }

    it do
      p = inverse_price + (inverse_price * deviation)
      expect(subject.valid_price?(p)).to eq(true)
    end

    it do
      request_amount = generate_decimal(market.amount_precision + 1)
      base_amount = market.round_amount(request_amount / price)
      expect(subject.conver_amount_to_base(request_amount)).to eq(base_amount)
    end
  end

  private

  def generate_decimal(precision)
    '1.1111111111111111'.to_d.round(precision)
  end
end
