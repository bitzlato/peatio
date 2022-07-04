# frozen_string_literal: true

module EthereumHelpers
  extend Memoist
  include EthereumGateway::Concern

  def ethereum_client
    @ethereum_client ||= Ethereum::Client.new(node_uri)
  end

  def node_uri
    'http://127.0.0.1:8545'
  end

  def stub_balance_fetching(blockchain_currency:, balance:, address:)
    response = { result: '0x' + (balance.to_s 16) }
    if blockchain_currency.contract_address.nil?
      stub_request(:post, node_uri)
        .with(body: /\{"jsonrpc":"2\.0","id":\d+,"method":"eth_getBalance","params":\["#{normalize_address(address)}","latest"\]\}/)
        .to_return(body: response.to_json)
    else
      stub_request(:post, node_uri)
        .with(body: /\{"jsonrpc":"2\.0","id":\d+,"method":"eth_call","params":\[\{"to":"#{blockchain_currency.contract_address}","data":"#{abi_encode('balanceOf(address)', normalize_address(address))}"\},"latest"\]\}/)
        .to_return(body: response.to_json)
    end
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
end

RSpec.configure { |config| config.include EthereumHelpers }
