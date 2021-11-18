# frozen_string_literal: true

describe ::EthereumGateway::Approver do
  subject(:approver) { described_class.new(client) }

  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:spender) { Faker::Blockchain::Ethereum.address }
  let(:secret) { SecureRandom.hex(5) }
  let(:gas_limit) { 22_000 }
  let(:contract_address) { Faker::Blockchain::Ethereum.address }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  it do
    gas_price = 1_000_000_000
    stub_gas_fetching(gas_price: gas_price, id: 1)
    data = abi_encode('approve(address,uint256)', spender, '0x' + EthereumGateway::Approver::ALLOWANCE_AMOUNT.to_s(16))
    request_body = { jsonrpc: '2.0',
                     id: 2,
                     method: :personal_sendTransaction,
                     params: [{
                       from: from_address,
                       to: contract_address,
                       data: data,
                       gas: '0x' + gas_limit.to_s(16),
                       gasPrice: '0x' + gas_price.to_s(16)
                     }, secret] }
    txid = '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017'
    stub_request(:post, uri)
      .with(body: request_body.to_json)
      .to_return(body: { result: txid, error: nil, id: 1 }.to_json)
    approver.call(from_address: from_address, spender: spender, secret: secret, gas_limit: gas_limit, contract_address: contract_address)
  end
end
