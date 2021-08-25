# encoding: UTF-8
# frozen_string_literal: true

describe Transaction do
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }
  let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'eth-rinkeby', key: 'eth-rinkeby' }

  context 'upsert_transaction' do
    let(:peatio_transaction) { Peatio::Transaction.new(
      txid: '1',
      txout: '2',
      currency_id: 'eth',
      amount: 1.2.to_money('eth'),
      fee: 0.001.to_money('eth'),
      from_address: from_address,
      to_address: to_address,
      block_number: 1,
      blockchain_id: blockchain.id,
      status: 'success',
      from: 'unknown',
      to: 'deposit'
    )}
    let(:reference) { create :deposit, :deposit_eth }

    it do
      expect(described_class.upsert_transaction! peatio_transaction).to be_a Transaction
    end
  end
end
