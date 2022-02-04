# frozen_string_literal: true

describe Transaction do
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }
  let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'eth-rinkeby', key: 'eth-rinkeby' }
  let(:blockchain_currency) { find_or_create :blockchain_currency, blockchain_id: blockchain.id, currency_id: 'eth' }

  context 'upsert_transaction' do
    let(:peatio_transaction) do
      Peatio::Transaction.new(
        txid: '1',
        txout: '2',
        currency_id: 'eth',
        amount: 1.2.to_money(blockchain_currency),
        fee: 0.001.to_money(blockchain_currency),
        from_address: from_address,
        to_address: to_address,
        block_number: 1,
        blockchain_id: blockchain.id,
        status: 'success',
        from: 'unknown',
        to: 'deposit'
      )
    end
    let(:reference) { create :deposit, :deposit_eth }

    context 'creates first time' do
      subject { described_class.upsert_transaction! peatio_transaction }

      it { expect(subject).to be_a described_class }
      it { expect(subject.kind).to eq 'deposit' }
    end

    context 'upsert second time' do
      subject { described_class.upsert_transaction! peatio_transaction }

      before do
        tx = described_class.upsert_transaction! peatio_transaction
        tx.update_columns kind: nil
      end

      it { expect(subject.kind).to eq 'deposit' }
      it { expect(subject.txout).to eq 2 }
    end
  end
end
