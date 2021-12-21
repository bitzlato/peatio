# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::BlockFetcher do
  include_context 'shared tron'

  describe '#fetch_block_transactions' do
    let(:contract_transfer_blocknum) { 23_079_498 }
    let(:smart_contract_trigger_blocknum) { 23_079_502 }

    it 'return balance for all currencies' do
      VCR.use_cassette('tron/fetch_block_transactions', record: :once) do
        transactions = gateway.fetch_block_transactions(contract_transfer_blocknum)
        expect(transactions).to be_a(Array)
        expect(transactions.size).to eq(1)
        transactions.each do |tx|
          expect(tx).to be_a(Peatio::Transaction)
          expect(tx.amount).to be_a(Money)
          expect(tx.amount.currency.id.to_s).to eq(trx.id)
          expect(tx.fee).to be_a(Money)
          expect(tx.fee.currency.id.to_s).to eq(trx.id)
        end

        transactions = gateway.fetch_block_transactions(smart_contract_trigger_blocknum)
        expect(transactions).to be_a(Array)
        expect(transactions.size).to eq(1)
        transactions.each do |tx|
          expect(tx).to be_a(Peatio::Transaction)
          expect(tx.amount).to be_a(Money)
          expect(tx.amount.currency.id.to_s).to eq(usdj_trc20.id)
          expect(tx.fee).to be_a(Money)
          expect(tx.fee.currency.id.to_s).to eq(trx.id)
        end
      end
    end
  end
end
