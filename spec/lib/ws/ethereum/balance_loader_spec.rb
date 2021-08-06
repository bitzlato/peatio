# encoding: UTF-8
# frozen_string_literal: true

describe WS::Ethereum::BalanceLoader do
  let(:eth) { Currency.find_by(id: :eth) }
  let(:usdt) { Currency.find_by(id: 'usdt-erc20') }

  context :load_eth_balance do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end
  end

  context do
    let(:response1) do
      {
        jsonrpc: '2.0',
        result: '0x71a5c4e9fe8a100',
        id: 1
      }
    end

    let(:response2) do
      {
        jsonrpc: '2.0',
        result: '0x7a120',
        id: 1
      }
    end

    let(:settings1) do
      {
        wallet:
          { address: 'something',
            uri: 'http://127.0.0.1:8545' },
        currency: eth.to_blockchain_api_settings
      }
    end

    let(:settings2) do
      {
        wallet:
          { address: 'something',
            uri: 'http://127.0.0.1:8545' },
        currency: trst.to_blockchain_api_settings
      }
    end

    before do
      stub_request(:post, 'http://127.0.0.1:8545')
        .with(body: { jsonrpc: '2.0',
                      id: 1,
                      method: :eth_getBalance,
                      params:
                        %w[
                          something
                          latest
                        ] }.to_json)
        .to_return(body: response1.to_json)

      stub_request(:post, 'http://127.0.0.1:8545')
        .with(body: { jsonrpc: '2.0',
                      id: 1,
                      method: :eth_call,
                      params:
                        [
                          {
                            to: '0x87099add3bcc0821b5b151307c147215f839a110',
                            data: '0x70a082310000000000000000000000000000000000000000000000000000000something'
                          },
                          'latest'
                        ] }.to_json)
        .to_return(body: response2.to_json)
    end

    it 'requests rpc eth_getBalance and get balance' do
      wallet.configure(settings1)
      result = wallet.load_balance!
      expect(result).to be_a(BigDecimal)
      expect(result).to eq('0.51182300042'.to_d)
    end

    it 'requests rpc eth_call and get token balance' do
      wallet.configure(settings2)
      result = wallet.load_balance!
      expect(result).to be_a(BigDecimal)
      expect(result).to eq('0.5'.to_d)
    end
  end
end
