# frozen_string_literal: true

describe ::EthereumGateway::AddressCreator do
  subject { described_class.new(client) }

  let(:address) { 'address' }
  let(:base_factor) { currency.base_factor }

  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  # context :create_address! do
  # around do |example|
  # WebMock.disable_net_connect!
  # example.run
  # WebMock.allow_net_connect!
  # end

  # let(:uri) { 'http://127.0.0.1:8545' }
  # let(:uri_with_path) { 'http://127.0.0.1:8545/path/extra' }

  # let(:settings) do
  # {
  # wallet:
  # { address: 'something',
  # uri: uri },
  # currency: {}
  # }
  # end

  # before do
  # PasswordGenerator.stubs(:generate).returns('pass@word')
  # wallet.configure(settings)
  # end

  # it 'request rpc and creates new address' do
  # address = '0x6d6cabaa7232d7f45b143b445114f7e92350a2aa'
  # stub_request(:post, uri)
  # .with(body: { jsonrpc: '2.0',
  # id: 1,
  # method: :personal_newAccount,
  # params: ['pass@word'] }.to_json)
  # .to_return(body: { jsonrpc: '2.0',
  # result: address,
  # id: 1 }.to_json)

  # result = wallet.create_address!(uid: 'UID123')
  # expect(result.as_json.symbolize_keys).to eq(address: address, secret: 'pass@word')
  # end

  # it 'works with wallet path' do
  # wallet.configure({
  # wallet:
  # { address: 'something',
  # uri: uri_with_path },
  # currency: {}
  # })
  # address = '0x6d6cabaa7232d7f45b143b445114f7e92350a2aa'
  # stub_request(:post, uri_with_path)
  # .with(body: { jsonrpc: '2.0',
  # id: 1,
  # method: :personal_newAccount,
  # params: ['pass@word'] }.to_json)
  # .to_return(body: { jsonrpc: '2.0',
  # result: address,
  # id: 1 }.to_json)

  # result = wallet.create_address!(uid: 'UID123')
  # expect(result.as_json.symbolize_keys).to eq(address: address, secret: 'pass@word')
  # end
  # end
end
