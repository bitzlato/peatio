# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway do
  let(:address) { 'address' }
  # let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'btc-testnet' }
  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }

  subject { described_class.new(blockchain) }
  before do
    described_class.any_instance.expects(:build_client).returns(client)
  end

  context '#collect!' do
    let!(:hot_wallet) { find_or_create :wallet, :eth_hot, name: 'Ethereum Hot Wallet' }
    let(:blockchain) { hot_wallet.blockchain }
    let(:peatio_transaction) { Peatio::Transaction.new(
      currency_id: 'eth',
      amount: 12,
      from_address: '123',
      to_address: '145',
      block_number: 1,
      status: 'pending'
    )}
    let!(:payment_address) { create :payment_address, :eth_address }
    let(:balances) {
      {
        Money::Currency.find('eth') => 1.to_money('eth'),
        Money::Currency.find('usdt-erc20') => 1.to_money('usdt-erc20'),
      }
    }
    it do
      Blockchain.any_instance.expects(:hot_wallet).returns hot_wallet
      EthereumGateway::TransactionCreator.
        any_instance.
        stubs(:call).
        with(from_address:  payment_address.address,
             to_address: hot_wallet.address,
             amount: 1000000,
             secret: nil,
            subtract_fee: true,
             contract_address: Money::Currency.find('usdt-erc20').contract_address).
             once.
             returns(peatio_transaction)
      EthereumGateway::TransactionCreator.
        any_instance.
        stubs(:call).
        with(from_address:  payment_address.address,
             to_address: hot_wallet.address,
             amount: 1000000000000000000,
             secret: nil,
             subtract_fee: true,
             contract_address: nil).
             once.
             returns(peatio_transaction)
      EthereumGateway.any_instance.expects(:load_balances).returns(balances)
      subject.send(:collect!, payment_address)
    end
  end
end