# encoding: UTF-8
# frozen_string_literal: true

describe ::AbstractGateway do
  let(:address) { 'address' }
  let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'btc-testnet' }
  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }

  subject { described_class.new(blockchain) }
  before do
    described_class.any_instance.expects(:build_client).returns(client)
  end

  context '#save_transaction' do
    let(:peatio_transaction) { Peatio::Transaction.new(
      currency_id: 'eth',
      amount: 1.2,
      from_address: '123',
      to_address: '145',
      block_number: 1,
      status: 'success'
    )}
    let(:reference) { create :deposit, :deposit_eth }

    it do
      expect { subject.send(:save_transaction, peatio_transaction, reference: reference) }.not_to raise_error
    end
  end
end
