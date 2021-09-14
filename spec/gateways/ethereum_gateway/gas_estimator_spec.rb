# frozen_string_literal: true

describe ::EthereumGateway::GasEstimator do
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:gas_price) { 10 }
  let(:to_address) { Faker::Blockchain::Ethereum.address }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context 'returns estimated gas' do
    subject do
      described_class.new(ethereum_client).call(
        from_address: from_address, contract_addresses: contract_addresses, to_address: to_address, account_native: true
      )
    end

    let(:contract_addresses) { [Faker::Blockchain::Ethereum.address, Faker::Blockchain::Ethereum.address] }
    let(:estimated_gas1) { 1 }
    let(:estimated_gas2) { 2 }
    let(:estimated_gas3) { 3 }

    before do
      stub_gas_fetching gas_price: gas_price, id: 1
      stub_estimate_gas(
        gas_price: gas_price,
        id: 2,
        estimated_gas: estimated_gas1,
        from: from_address,
        to: contract_addresses.first.downcase,
        data: abi_encode('transfer(address,uint256)', to_address, '0x' + EthereumGateway::GasEstimator::DEFAULT_AMOUNT.to_s(16))
      )
      stub_estimate_gas(
        gas_price: gas_price,
        id: 3,
        estimated_gas: estimated_gas2,
        from: from_address,
        to: contract_addresses.second.downcase,
        data: abi_encode('transfer(address,uint256)', to_address, '0x' + EthereumGateway::GasEstimator::DEFAULT_AMOUNT.to_s(16))
      )
      stub_estimate_gas(
        gas_price: gas_price,
        id: 4,
        estimated_gas: estimated_gas3,
        from: from_address,
        to: to_address,
        value: 1
      )
    end

    it do
      expect(subject).to eq (estimated_gas1 + estimated_gas2 + estimated_gas3)
    end
  end

  context 'returns configured gas' do
    subject do
      described_class.new(ethereum_client).call(
        from_address: from_address,
        contract_addresses: contract_addresses,
        to_address: to_address,
        account_native: false,
        gas_limits: { contract_addresses.first => estimated_gas1 }
      )
    end

    let(:contract_addresses) { [Faker::Blockchain::Ethereum.address] }
    let(:estimated_gas1) { 1 }

    before do
      stub_gas_fetching gas_price: gas_price, id: 1
      body = {
        jsonrpc: '2.0',
        id: 2,
        method: 'eth_estimateGas',
        params: [
          {
            gasPrice: '0x' + gas_price.to_s(16),
            from: from_address,
            to: contract_addresses.first,
            data: abi_encode('transfer(address,uint256)', to_address, '0x' + EthereumGateway::GasEstimator::DEFAULT_AMOUNT.to_s(16))
          }
        ]
      }
      stub_request(:post, node_uri)
        .with(body: body.to_json)
        .to_raise(Ethereum::Client::NoEnoughtAmount.new(1, 2, 3))
    end

    it do
      expect(subject).to eq estimated_gas1
    end
  end
end
