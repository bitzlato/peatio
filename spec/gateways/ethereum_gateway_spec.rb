# frozen_string_literal: true

describe ::EthereumGateway do
  subject(:gateway) { described_class.new(blockchain) }

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

  describe '#approve!' do
    it do
      address = Faker::Blockchain::Ethereum.address
      secret = SecureRandom.hex(5)
      contract_address = Faker::Blockchain::Ethereum.address
      data = abi_encode('transfer(address,uint256)', contract_address, '0x1')
      stub_estimate_gas(from: address, to: contract_address, gas_price: 1, estimated_gas: 5_000_000_000, id: 2, data: data)
      fee_wallet = find_or_create(:wallet, :eth_fee, name: 'Ethereum Fee Wallet')
      approver_data = abi_encode('approve(address,uint256)', fee_wallet.address, '0x' + EthereumGateway::Approver::ALLOWANCE_AMOUNT.to_s(16))
      txid = '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017'
      stub_request(:post, 'http://127.0.0.1:8545/').with(
        body: "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"personal_sendTransaction\",\"params\":[{\"from\":\"#{address}\",\"to\":\"#{contract_address}\",\"data\":\"#{approver_data}\",\"gas\":\"0x12a05f200\",\"gasPrice\":\"0x1\"},\"#{secret}\"]}"
      ).to_return(body: { result: txid, error: nil, id: 3 }.to_json)
      gateway.approve!(address: address, secret: secret, spender_address: fee_wallet.address, contract_address: contract_address)
    end
  end
end
