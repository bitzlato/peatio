# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway::GasEstimator do
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_addresses) { [Faker::Blockchain::Ethereum.address, Faker::Blockchain::Ethereum.address] }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  before do
    stub_gas_fetching gas_price: gas_price, id: 1
    stub_estimate_gas gas_price: gas_price, id: 2, estimated_gas: estimated_gas1, from: from_address, to: to_addresses.first
    stub_estimate_gas gas_price: gas_price, id: 3, estimated_gas: estimated_gas2, from: from_address, to: to_addresses.second
  end

  subject { described_class.new(ethereum_client).call from_address: from_address, to_addresses: to_addresses }

  let(:gas_price) { 1234000 }
  let(:estimated_gas1) { 22345 }
  let(:estimated_gas2) { 122345 }

  it do
    expect(subject).to eq (estimated_gas1 + estimated_gas2)*gas_price
  end
end
