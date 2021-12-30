# frozen_string_literal: true

describe ::EthereumGateway do
  subject(:gateway) { described_class.new(blockchain) }

  let!(:hot_wallet) { find_or_create :wallet, :eth_hot, name: 'Ethereum Hot Wallet' }
  let(:blockchain) { hot_wallet.blockchain }
  let(:address) { Faker::Blockchain::Ethereum.address }
  let(:fee_wallet) { find_or_create(:wallet, :eth_fee, name: 'Ethereum Fee Wallet') }
  let(:secret) { SecureRandom.hex(5) }
  let(:txid) { '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017' }
  let(:gas_price) { 1 }

  before do
    stub_gas_fetching gas_price: 1, id: 1
    Blockchain.any_instance.stubs(:hot_wallet).returns(hot_wallet)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  describe '#refuel_gas!' do
    context 'when USE_PRIVATE_KEY is not true' do
      it 'refuels gas' do
        EthereumGateway::BalanceLoader.any_instance.stubs(:call).returns(0)
        EthereumGateway::AbstractCommand.any_instance.stubs(:fetch_gas_price).returns(gas_price)
        stub_balance_fetching(blockchain_currency: blockchain.blockchain_currencies[0], balance: 0, address: address, id: 1)
        stub_personal_send_transaction(from_address: fee_wallet.address, secret: fee_wallet.secret, to_address: address, value: 132_000, gas_price: gas_price, gas: 21_000, id: 2, txid: txid)
        gateway.refuel_gas!(address)
      end
    end

    context 'when USE_PRIVATE_KEY is true' do
      before do
        ENV['USE_PRIVATE_KEY'] = 'true'
      end

      after do
        ENV.delete('USE_PRIVATE_KEY')
      end

      it 'refuels gas' do
        fee_blockchain_address = create(:blockchain_address)
        fee_wallet.update!(address: fee_blockchain_address.address)
        EthereumGateway::BalanceLoader.any_instance.stubs(:call).returns(0)
        EthereumGateway::AbstractCommand.any_instance.stubs(:fetch_gas_price).returns(gas_price)
        Eth::Tx.any_instance.stubs(:hex).returns('data')
        stub_balance_fetching(blockchain_currency: blockchain.blockchain_currencies[0], balance: 0, address: address, id: 1)
        stub_get_transaction_count(id: 2, address: fee_blockchain_address.address, count: 0)
        stub_send_raw_transaction(id: 3, txid: txid, data: 'data')
        gateway.refuel_gas!(address)
      end
    end
  end

  describe '#approve!' do
    it 'approves' do
      contract_address = blockchain.blockchain_currencies[1].contract_address
      approver_data = abi_encode('approve(address,uint256)', fee_wallet.address, '0x' + EthereumGateway::Approver::ALLOWANCE_AMOUNT.to_s(16))
      stub_request(:post, 'http://127.0.0.1:8545/').with(
        body: "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"personal_sendTransaction\",\"params\":[{\"from\":\"#{address}\",\"to\":\"#{contract_address}\",\"data\":\"#{approver_data}\",\"gas\":\"0x15f90\",\"gasPrice\":\"0x#{gas_price.to_s(16)}\"},\"#{secret}\"]}"
      ).to_return(body: { result: txid, error: nil, id: 2 }.to_json)
      gateway.approve!(address: address, secret: secret, spender_address: fee_wallet.address, contract_address: contract_address)
    end
  end

  describe '#create_address!' do
    context 'when USE_PRIVATE_KEY is not true' do
      before do
        ENV['USE_PRIVATE_KEY'] = 'false'
      end

      after do
        ENV.delete('USE_PRIVATE_KEY')
      end

      it 'create personal address' do
        described_class
          .any_instance
          .expects(:create_personal_address!)

        gateway.create_address!
      end
    end

    context 'when USE_PRIVATE_KEY is true' do
      before do
        ENV['USE_PRIVATE_KEY'] = 'true'
      end

      after do
        ENV.delete('USE_PRIVATE_KEY')
      end

      it 'create private address' do
        described_class
          .any_instance
          .expects(:create_private_address!)

        gateway.create_address!
      end
    end
  end
end
