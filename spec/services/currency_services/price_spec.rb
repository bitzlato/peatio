# frozen_string_literal: true

RSpec.describe CurrencyServices::Price do
  subject(:service) { described_class.new(base_currency: base_currency, quote_currency: quote_currency) }

  describe '#call' do
    after { delete_measurments('trades') }

    context 'when direct market exists' do
      let(:base_currency) { find_or_create(:currency, id: :btc) }
      let(:quote_currency) { find_or_create(:currency, id: :usd) }

      it 'calculates price' do
        create(:trade, :btc_usd, price: '5.0'.to_d, amount: '1.1'.to_d, total: '5.5'.to_d).write_to_influx
        expect(service.call).to eq 5
      end
    end

    context 'when only intermediate market exists' do
      let(:base_currency) { find_or_create(:currency, id: :eth) }
      let(:quote_currency) { find_or_create(:currency, id: :usd) }

      it 'calculates price' do
        create(:trade, :btc_usd, price: '5.0'.to_d, amount: '1.1'.to_d, total: '5.5'.to_d).write_to_influx
        create(:trade, :btc_eth, price: '2.0'.to_d, amount: '1.1'.to_d, total: '2.2'.to_d).write_to_influx
        expect(service.call).to eq 2.5
      end
    end
  end
end
