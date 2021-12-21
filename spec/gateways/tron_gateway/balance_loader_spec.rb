# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::BalanceLoader do
  include_context 'shared tron'

  describe '#load_balances' do
    it 'return balance for all currencies' do
      VCR.use_cassette('tron/load_balances', record: :once) do
        amounts = gateway.load_balances(hot_wallet.address)
        expect(amounts).to be_a(Hash)

        amounts.each do |currency_id, amount|
          expect(amount).to be_a(Money)
          expect(amount.currency).to eq(currency_id)
        end
      end
    end
  end

  describe '#load_balance' do
    it 'return balance for currency' do
      VCR.use_cassette('tron/load_balance', record: :once) do
        amount = gateway.load_balance(hot_wallet.address, trx)
        expect(amount).to be_a(Money)
      end
    end
  end

  describe '#fetch_balance' do
    it 'returns balance in native currency' do
      VCR.use_cassette('tron/fetch_balance', record: :once) do
        amount = gateway.fetch_balance(hot_wallet.address)
        expect(amount).to be_a(Money)
      end
    end
  end
end
