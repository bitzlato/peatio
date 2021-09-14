# frozen_string_literal: true

module EthereumHelpers
  extend Memoist

  def ethereum_client
    @ethereum_client ||= Ethereum::Client.new(node_uri)
  end

  def node_uri
    'http://127.0.0.1:8545'
  end

  def stub_balance_fetching(balance:, address:, id:)
    response = { jsonrpc: '2.0', result: '0x' + (balance.to_s 16), id: 1 }
    stub_request(:post, node_uri)
      .with(body: { jsonrpc: '2.0',
                    id: 1,
                    method: :eth_getBalance,
                    params: [address, 'latest'] }.to_json)
      .to_return(body: response.to_json)
  end

  def stub_gas_fetching(gas_price:, id:)
    body = {
      jsonrpc: '2.0',
      id: id,
      method: 'eth_gasPrice',
      params: []
    }
    stub_request(:post, node_uri)
      .with(body: body.to_json)
      .to_return(body: { result: '0x' + gas_price.to_s(16), error: nil, id: id }.to_json)
  end

  def stub_estimate_gas(from:, to:, gas_price:, estimated_gas:, id:, data: nil, value: nil)
    body = {
      jsonrpc: '2.0',
      id: id,
      method: 'eth_estimateGas',
      params: [
        { gasPrice: '0x' + gas_price.to_s(16), from: from, to: to, data: data, value: value.nil? ? nil : '0x' + value.to_s(16) }.compact
      ]
    }
    stub_request(:post, node_uri)
      .with(body: body.to_json)
      .to_return(body: { result: '0x' + estimated_gas.to_s(16), error: nil, id: id }.to_json)
  end

  def stub_personal_send_transaction(from_address:, to_address:, value:, gas_price:, gas:, id:)
    request_body = { jsonrpc: '2.0',
                     id: id,
                     method: :personal_sendTransaction,
                     params: [{
                       from: from_address,
                       to: to_address,
                       value: '0x' + (value.to_s 16),
                       gas: '0x' + (gas.to_s 16),
                       gasPrice: '0x' + (gas_price.to_s 16)
                     }, secret] }
    stub_request(:post, node_uri)
      .with(body: request_body.to_json)
      .to_return(body: { result: txid, error: nil, id: id }.to_json)
  end
end

RSpec.configure { |config| config.include EthereumHelpers }
