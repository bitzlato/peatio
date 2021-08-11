# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway::BalanceLoader do
  let(:address) { 'address' }
  let(:base_factor) { currency.base_factor }

  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }
  subject { described_class.new(client) }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context 'get eth balance' do
    let(:currency) { Money::Currency.find('eth') }
    let(:response) do
      {
        jsonrpc: '2.0',
        result: '0x71a5c4e9fe8a100',
        id: 1
      }
    end

    before do
      stub_request(:post, uri)
        .with(body: { jsonrpc: '2.0',
                      id: 1,
                      method: :eth_getBalance,
                      params: [address, 'latest'] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'requests rpc eth_getBalance and get balance' do
      result = subject.call(address, base_factor)
      expect(result).to be_a(BigDecimal)
      expect(result).to eq('0.51182300042'.to_d)
    end
  end

  context 'get token balance' do
    let(:currency) { Money::Currency.find('usdt-erc20') }
    let(:response) do
      {
        jsonrpc: '2.0',
        result: '0x7a120',
        id: 1
      }
    end
    let(:contract_address) { '0x87099add3bcc0821b5b151307c147215f839a110' }

    before  do
      stub_request(:post, uri)
        .with(body: { jsonrpc: '2.0',
                      id: 1,
                      method: :eth_call,
                      params:
                      [
                        {
                          to: contract_address,
                          data: '0x70a08231000000000000000000000000000000000000000000000000000000000' + address
                        },
                        'latest'
                      ] }.to_json)
                        .to_return(body: response.to_json)
    end

    it 'requests rpc eth_call and get token balance' do
      result = subject.call(address, base_factor, contract_address)
      expect(result).to be_a(BigDecimal)
      expect(result).to eq('0.5'.to_d)
    end
  end
end
