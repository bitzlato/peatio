# frozen_string_literal: true

describe ::EthereumGateway::CollectionConcern do
  subject { EthereumGateway.new(blockchain) }

  let!(:hot_wallet) { find_or_create :wallet, :eth_hot, name: 'Ethereum Hot Wallet' }
  let(:blockchain) { hot_wallet.blockchain }

  before do
    EthereumGateway.any_instance.expects(:build_client).returns(ethereum_client)
    Blockchain.any_instance.stubs(:hot_wallet).returns(hot_wallet)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  describe '#collect!' do
    let(:eth_money_amount) { 2.to_money('eth') }
    let(:balances) { { Money::Currency.find('eth') => eth_money_amount } }
    let(:payment_address) { create :payment_address, blockchain: blockchain }
    let(:gas_limits) { { nil => nil } }

    context 'there are native and tokens on the address' do
      before do
        stub_gas_fetching gas_price: 1, id: 1
        stub_balance_fetching address: payment_address.address, balance: 1, id: 2
      end

      it 'collects tokens first' do
        Blockchain
          .any_instance
          .expects(:hot_wallet)
          .returns hot_wallet
        EthereumGateway::Collector
          .any_instance
          .stubs(:call)
          .with(from_address: payment_address.address,
                to_address: hot_wallet.address,
                amounts: { nil => eth_money_amount.base_units },
                gas_factor: 1,
                gas_limits: gas_limits,
                private_key: nil,
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
end
