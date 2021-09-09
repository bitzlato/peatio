# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway do
  let!(:hot_wallet) { find_or_create :wallet, :eth_hot, name: 'Ethereum Hot Wallet' }
  let(:blockchain) { hot_wallet.blockchain }

  subject { described_class.new(blockchain) }
  before do
    described_class.any_instance.expects(:build_client).returns(ethereum_client)
    stub_gas_fetching gas_price: 1, id: 1
    Blockchain.any_instance.stubs(:hot_wallet).returns(hot_wallet)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context '#collect!' do
    let(:eth_money_amount) { 2.to_money('eth') }
    let(:balances) { { Money::Currency.find('eth') => eth_money_amount} }
    let(:payment_address) { create :payment_address, blockchain: blockchain }

    it 'collects tokens first' do
      Blockchain.any_instance.expects(:hot_wallet).returns hot_wallet
      EthereumGateway::Collector
        .any_instance
        .stubs(:call)
        .with(from_address:  payment_address.address,
              to_address: hot_wallet.address,
              amounts: {nil => eth_money_amount.base_units },
              gas_factor: 1,
              secret: payment_address.secret)
        .once
      EthereumGateway
        .any_instance
        .expects(:load_balances)
        .returns(balances)
      subject.send(:collect!, payment_address)
    end
  end
end
