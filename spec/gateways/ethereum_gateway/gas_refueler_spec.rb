# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway::GasRefueler do
  let(:address) { 'address' }
  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }
  let(:eth) { Currency.find_by(id: :eth) }
  let(:trst) { Currency.find_by(id: :trst) }
  let(:ring) { Currency.find_by(id: :ring) }
  let(:secret) { SecureRandom.hex(5) }
  let(:amount) { (1.1.to_d * base_factor).to_i }
  let(:txid) { '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017' }
  let(:fetched_gas_price) { 1_000_000_000 }
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }
  let(:gas_limit) { 21000 }

  subject { described_class.new(client) }

  before do
    stub_gas_fetching fetched_gas_price
    stub_balance_fetching ethereum_balance, to_address
  end

  def stub_balance_fetching(balance, address)
    response = {
      jsonrpc: '2.0',
      result: '0x' + (balance.to_s 16),
      id: 1
    }
    stub_request(:post, uri)
      .with(body: { jsonrpc: '2.0',
                    id: 1,
                    method: :eth_getBalance,
                    params: [address, 'latest'] }.to_json)
      .to_return(body: response.to_json)
  end

  def stub_gas_fetching(gas_price)
    id = 2
    eth_GasPrice = {
      "jsonrpc": '2.0',
      "id": id,
      "method": 'eth_gasPrice',
      "params": []
    }
    stub_request(:post, uri)
      .with(body: eth_GasPrice.to_json)
      .to_return(body: { result: '0x' + gas_price.to_s(16),
                         error: nil,
                         id: id }.to_json)

  end

  def stub_personal_sendTransaction
    request_body = { jsonrpc: '2.0',
                     id: 3,
                     method: :personal_sendTransaction,
                     params: [{
                       from: from_address,
                       to: to_address,
                       value: '0x' + (value.to_s 16),
                       gas: '0x' + (gas_limit.to_s 16),
                       gasPrice: '0x' + (transaction_gas_price.to_s 16)
                     }, secret] }
    stub_request(:post, uri)
      .with(body: request_body.to_json)
      .to_return(body: { result: txid, error: nil, id: 3 }.to_json)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  let(:result) do
    subject.call(
      base_gas_limit: gas_limit,
      token_gas_limit: token_gas_limit,
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
      let(:ethereum_balance) { 0 }
      it { expect{ result }.to raise_error described_class::NoTokens }
    end
    context 'it has small ethereum balance' do
      let(:ethereum_balance) { 10000 }
      it { expect{ result }.to raise_error described_class::NoTokens }
    end
    context 'it has big ethereum balance' do
      let(:ethereum_balance) { 10**18 }
      it { expect{ result }.to raise_error described_class::NoTokens }
    end
  end

  context 'address has tokens' do
    let(:ethereum_balance) { 0 }
    let(:contract_addresses) { [Faker::Blockchain::Ethereum.address]  }

    context 'and it has no enough ethereum balance' do
      before do
        stub_personal_sendTransaction
      end
      let(:ethereum_balance) { 10000 }
      let(:refuel_gas_factor) { 1 }
      let(:value) { (fetched_gas_price * tokens_count * token_gas_limit * refuel_gas_factor).to_i - ethereum_balance }
      let(:transaction_gas_price) { (fetched_gas_price * refuel_gas_factor).to_i }
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
            'subtract_fee' => false
          }
        }
      end
      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end
    context 'and it has enough ethereum balance' do
      let(:ethereum_balance) { 10**18 }
      it { expect{ result }.to raise_error described_class::Balanced }
    end
  end

  context 'address has no ethereum and has no tokens' do
    pending
  end
end
