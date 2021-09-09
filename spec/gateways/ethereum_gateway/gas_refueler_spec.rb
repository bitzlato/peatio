# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway::GasRefueler do
  let(:eth) { Currency.find_by(id: :eth) }
  let(:trst) { Currency.find_by(id: :trst) }
  let(:ring) { Currency.find_by(id: :ring) }
  let(:secret) { SecureRandom.hex(5) }
  let(:amount) { (1.1.to_d * base_factor).to_i }
  let(:txid) { '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017' }
  let(:gas_price) { 1_000_000_000 }
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }
  let(:refuel_gas_factor) { 1 }
  let(:estimated_gas) { 1231230 }
  let(:gas_limit) { estimated_gas }

  subject { described_class.new(ethereum_client) }

  before do
    stub_balance_fetching balance: balance_on_target_address, address: to_address, id: 1
    stub_gas_fetching gas_price: gas_price, id: 2
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  let(:result) do
    subject.call(
      gas_factor: refuel_gas_factor,
      gas_wallet_address: from_address,
      gas_wallet_secret: secret,
      target_address: to_address,
      contract_addresses: contract_addresses
    )
  end

  context 'address has no tokens' do
    let(:contract_addresses) { [] }
    context 'it has zero ethereum balance' do
      let(:balance_on_target_address) { 0 }
      it { expect{ result }.to raise_error described_class::NoTokens }
    end
    context 'it has small ethereum balance' do
      let(:balance_on_target_address) { 10000 }
      it { expect{ result }.to raise_error described_class::NoTokens }
    end
    context 'it has big ethereum balance' do
      let(:balance_on_target_address) { 10**18 }
      it { expect{ result }.to raise_error described_class::NoTokens }
    end
  end

  context 'address has tokens' do
    let(:balance_on_target_address) { 0 }
    let(:contract_addresses) { [Faker::Blockchain::Ethereum.address]  }
    before do
      stub_estimate_gas(
        id: 3,
        from: from_address,
        to: contract_addresses.first,
        gas_price: gas_price,
        estimated_gas: estimated_gas,
        data: abi_encode('transfer(address,uint256)', to_address, '0x'+EthereumGateway::GasEstimator::DEFAULT_AMOUNT.to_s(16))
      )
      stub_estimate_gas id: 4, from: from_address, to: to_address, gas_price: gas_price, estimated_gas: estimated_gas
    end

    context 'and it has no enough ethereum balance' do
      before do
        stub_personal_sendTransaction(
          value:        value,
          from_address: from_address,
          to_address:   to_address,
          gas:          gas_limit,
          gas_price:    gas_price,
          id:           5
        )
      end
      let(:balance_on_target_address) { 10000 }
      let(:value) { (gas_price * estimated_gas * 2 * refuel_gas_factor).to_i - balance_on_target_address }
      let(:transaction_gas_price) { (gas_price * refuel_gas_factor).to_i }
      let(:result_transaction_hash) do
        {
          amount: value,
          to_address: to_address,
          hash: txid,
          status: 'pending',
          from_addresses: [from_address],
          options: {
            'gas_factor' => refuel_gas_factor,
            'gas_limit' =>  gas_limit,
            'gas_price' =>  transaction_gas_price,
            'subtract_fee' => false,
            'required_amount' => 2462460000000000,
            'required_gas' => estimated_gas
          }
        }
      end
      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end
    context 'and it has enough ethereum balance' do
      let(:balance_on_target_address) { 10**18 }
      it { expect{ result }.to raise_error described_class::Balanced }
    end
  end
end
