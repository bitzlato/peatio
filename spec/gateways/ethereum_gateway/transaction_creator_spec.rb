# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway::TransactionCreator do
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
  let(:gas_limit) { 22_000 }
  let(:gas_factor) { 1 }

  subject { described_class.new(client) }

  before do
    stub_gas_fetching gas_price: fetched_gas_price, id: 1
    stub_personal_send_transaction
  end

  let(:request_body) do
    { jsonrpc: '2.0',
      id: 2,
      method: :personal_sendTransaction,
      params: [{
        from: from_address,
        to: to_address,
        value: '0x' + (value.to_s 16),
        gas: '0x' + (gas_limit.to_s 16),
        gasPrice: '0x' + (transaction_gas_price.to_s 16)
      }, secret] }
  end

  def stub_personal_send_transaction
    stub_request(:post, uri)
      .with(body: request_body.to_json)
      .to_return(body: { result: txid, error: nil, id: 1 }.to_json)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  let(:result) do
    subject.call(
      amount:           amount,
      gas_limit:        gas_limit,
      from_address:     from_address,
      to_address:       to_address,
      secret:           secret,
      subtract_fee:     subtract_fee,
      gas_factor:       gas_factor,
      contract_address: contract_address
    )
  end

  context 'eth transaction' do
    let(:base_factor) { eth.base_factor }
    let(:contract_address) { nil }
    let(:subtract_fee) { false }
    let(:result_transaction_hash) do
      {
        amount: value,
        to_address: to_address,
        hash: txid,
        status: 'pending',
        from_addresses: [from_address],
        options: {
          'gas_factor' => gas_factor,
          'gas_limit' => gas_limit,
          'gas_price' => transaction_gas_price,
          'subtract_fee' => subtract_fee
        }
      }
    end
    context 'transaction with subtract fees' do
      let(:transaction_gas_price) { fetched_gas_price }
      let(:value) { amount - (gas_limit * transaction_gas_price) }
      let(:subtract_fee) { true }
      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end

    context 'without subtract fees' do
      let(:value) { amount }
      let(:transaction_gas_price) { fetched_gas_price }
      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end

    context 'custom gas_price and subcstract fees' do
      let(:gas_factor) { 1.1 }
      let(:transaction_gas_price) { (fetched_gas_price * gas_factor).to_i }
      let(:value) { amount - (gas_limit * transaction_gas_price) }
      let(:subtract_fee) { true }
      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end
  end

  context 'erc20 transaction for trst' do
    let(:base_factor) { trst.base_factor }
    let(:to_address) { '0x6d6cabaa7232d7f45b143b445114f7e92350a2aa' }
    let(:transaction_gas_price) { fetched_gas_price }
    let(:subtract_fee) { false }
    let(:contract_address) { trst.options.fetch('erc20_contract_address') }
    let(:request_body) do
      { jsonrpc: '2.0',
        id: 2,
        method: :personal_sendTransaction,
        params: [{
          from: from_address,
          to: contract_address,
          data: '0xa9059cbb0000000000000000000000006d6cabaa7232d7f45b143b445114f7e92350a2aa000000000000000000000000000000000000000000000000000000000010c8e0',
          gas: '0x' + (gas_limit.to_s 16),
          gasPrice: '0x' + transaction_gas_price.to_s(16)
        }, secret] }
    end
    let(:result_transaction_hash) do
      {
        from_addresses: [from_address],
        amount: amount,
        to_address: to_address,
        contract_address: contract_address,
        hash: txid,
        status: 'pending',
        options: {
          'gas_limit' => gas_limit,
          'gas_factor' => gas_factor,
          'gas_price' => transaction_gas_price
        }
      }
    end

    it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
  end
end
