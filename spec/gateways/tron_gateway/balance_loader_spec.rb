# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::BalanceLoader, :tron do
  describe '#load_balances' do
    it 'return balance for all currencies' do
      VCR.use_cassette('tron/load_balances', record: :once) do
        amounts = tron_gateway.load_balances(tron_hot_wallet.address)
        expect(amounts).to be_a(Hash)

        amounts.each do |currency_id, amount|
          expect(amount).to be_a(Money)
          expect(currency_id).to eq(amount.currency.blockchain.blockchain_currencies.find(amount.currency.id.to_s.to_i).currency_id)
        end
      end
    end
  end

  describe '#load_balance' do
    it 'return balance for currency' do
      VCR.use_cassette('tron/load_balance', record: :once) do
        amount = tron_gateway.load_balance(tron_hot_wallet.address, tron_trx)
        expect(amount).to be_a(Money)
      end
    end
  end

  describe '#fetch_balance' do
    it 'returns balance in native currency' do
      VCR.use_cassette('tron/fetch_balance', record: :once) do
        amount = tron_gateway.fetch_balance(tron_hot_wallet.address)
        expect(amount).to be_a(Money)
      end
    end
  end
end
