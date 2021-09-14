# encoding: UTF-8
# frozen_string_literal: true

describe ::AbstractGateway do
  let(:address) { 'address' }
  let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'btc-testnet', key: 'btc-testnet' }
  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }

  subject { described_class.new(blockchain) }
  before do
    described_class.any_instance.expects(:build_client).returns(client)
  end

  context '#monefy_transaction' do
    context 'monefy hash transcation' do
      let(:hash_transaction) do
        {
          currency_id: 'eth',
          amount: 1000000000002,
          from_address: '123',
          to_address: '145',
          block_number: 1,
          status: 'success',
          contract_address: nil
        }
      end
      let(:reference) { create :deposit, :deposit_eth }

      it do
        expect do
          subject.send(:monefy_transaction, hash_transaction, reference: reference)
        end.not_to raise_error
      end
    end
    context 'monefy peatio transcation' do
      let(:peatio_transaction) do
        Peatio::Transaction.new(
          currency_id: 'eth',
          amount: 100000000002,
          from_address: '123',
          to_address: '145',
          block_number: 1,
          status: 'success'
        )
      end
      let(:reference) { create :deposit, :deposit_eth }

      it do
        expect do
          subject.send(:monefy_transaction, peatio_transaction, reference: reference)
        end.not_to raise_error
      end
    end
  end
end
