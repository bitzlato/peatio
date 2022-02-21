# frozen_string_literal: true

RSpec.describe ::EthereumGateway::BlockFetcher do
  subject(:block_fetcher) { described_class.new(blockchain.gateway.client) }

  let(:blockchain) { find_or_create(:blockchain, 'eth-rinkeby', key: 'eth-rinkeby') }
  let(:block_number) { 1 }

  before do
    stub_get_block_by_number(block_number: block_number, transactions: transactions)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context 'when contract address is whitelisted' do
    let(:contract_address) { '0xd1c5966f9f5ee6881ff6b261bbeda45972b1b5f3' }
    let(:hash) { '0xb3c50b55e5802093b3f4cc9e811a228b902b1671bce5a316d1c7b7174f7112ef' }
    let(:transactions) do
      [{
        from: '0x2a038e100f8b85df21e4d44121bdbfe0c288a869',
        to: contract_address,
        value: '0x0',
        input: '0x1',
        hash: hash
      }]
    end

    before do
      create(:whitelisted_smart_contract, blockchain: blockchain, address: contract_address, state: 'active')
    end

    it 'processes transaction' do
      EthereumGateway::AbstractCommand.any_instance.expects(:fetch_receipt!).with(hash).once
      EthereumGateway::AbstractCommand.any_instance.expects(:build_erc20_transactions).returns([]).once

      block_fetcher.call(block_number, contract_addresses: blockchain.contract_addresses, follow_addresses: blockchain.follow_addresses, follow_txids: blockchain.follow_txids.presence, whitelisted_addresses: blockchain.whitelisted_addresses)
    end
  end

  context 'when contract address is not whitelisted' do
    let(:hash) { '0xb3c50b55e5802093b3f4cc9e811a228b902b1671bce5a316d1c7b7174f7112ef' }
    let(:transactions) do
      [{
        from: '0x2a038e100f8b85df21e4d44121bdbfe0c288a869',
        to: '0xd1c5966f9f5ee6881ff6b261bbeda45972b1b5f3',
        value: '0x0',
        input: '0x1',
        hash: hash
      }]
    end

    it 'does not process transaction' do
      EthereumGateway::AbstractCommand.any_instance.expects(:fetch_receipt!).with(hash).never
      EthereumGateway::AbstractCommand.any_instance.expects(:build_erc20_transactions).returns([]).never

      block_fetcher.call(block_number, contract_addresses: blockchain.contract_addresses, follow_addresses: blockchain.follow_addresses, follow_txids: blockchain.follow_txids.presence, whitelisted_addresses: blockchain.whitelisted_addresses)
    end
  end
end
