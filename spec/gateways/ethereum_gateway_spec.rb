# frozen_string_literal: true

describe ::EthereumGateway do
  subject { described_class.new(blockchain) }

  let!(:hot_wallet) { find_or_create :wallet, :eth_hot, name: 'Ethereum Hot Wallet' }
  let(:blockchain) { hot_wallet.blockchain }

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

  describe '#refuel_gas!' do
    pending
  end
end
