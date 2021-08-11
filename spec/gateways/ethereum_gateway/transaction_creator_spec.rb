# encoding: UTF-8
# frozen_string_literal: true

describe ::EthereumGateway::TransactionCreator do
  let(:address) { 'address' }
  let(:uri) { 'http://127.0.0.1:8545' }
  let(:client) { ::Ethereum::Client.new(uri) }

  let(:eth) { Currency.find_by(id: :eth) }
  let(:trst) { Currency.find_by(id: :trst) }
  let(:ring) { Currency.find_by(id: :ring) }
  let(:secret) { SecureRandom.hex(5) }
  let(:amount) { (1.1.to_d * base_factor).to_i }
  let(:base_factor) { eth.base_factor }
  let(:txid) { '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017' }
  let(:fetched_gas_price) { 1_000_000_000 }
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }
  let(:gas_limit) { EthereumGateway::TransactionCreator::DEFAULT_ETH_GAS_LIMIT }

  subject { described_class.new(client) }

  def stub_gas_fetching(gas_price)
    id = 1
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

  def stub_personal_sendTransaction(from:, to:, value:, gas: , gasPrice:)
    request_body = { jsonrpc: '2.0',
                     id: 2,
                     method: :personal_sendTransaction,
                     params: [{
                       from: from,
                       to: to,
                       value: '0x' + (value.to_s 16),
                       gas: '0x' + (gas.to_s 16),
                       gasPrice: '0x' + (gasPrice.to_s 16)
                     }, secret] }
    stub_request(:post, uri)
      .with(body: request_body.to_json)
      .to_return(body: { result: txid, error: nil, id: 1 }.to_json)
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context 'eth transaction' do
    let(:gas_factor) { 1 }
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
    let(:result) do
      subject.call(
        amount: amount,
        gas_limit: gas_limit,
        from_address: from_address,
        to_address: to_address,
        secret: secret,
        subtract_fee: subtract_fee,
        gas_factor: gas_factor
      )
    end
    before do
      stub_gas_fetching fetched_gas_price
      stub_personal_sendTransaction(
        from: from_address,
        to: to_address,
        value: value,
        gas: gas_limit,
        gasPrice: transaction_gas_price)

    end

    context 'transaction with subtract fees' do
      let(:transaction_gas_price) { fetched_gas_price }
      let(:value) { amount - gas_limit * transaction_gas_price }
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
      let(:value) { amount - gas_limit * transaction_gas_price }
      let(:subtract_fee) { true }
      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end
  end

  context 'erc20 transaction' do
    pending

    let(:request_body) do
      { jsonrpc: '2.0',
        id: 2,
        method: :personal_sendTransaction,
        params: [{
          from: deposit_wallet_eth.address.downcase,
          to: trst.options.fetch('erc20_contract_address'),
          data: '0xa9059cbb0000000000000000000000006d6cabaa7232d7f45b143b445114f7e92350a2aa000000000000000000000000000000000000000000000000000000000010c8e0',
          gas: '0x15f90',
          gasPrice: gas_price_hex
        }, secret] }
    end

    before do
      wallet.configure(settings)
    end

    it do
      stub_request(:post, uri)
        .with(body: eth_GasPrice.to_json)
        .to_return(body: { result: gas_price_hex,
                           error: nil,
                           id: 1 }.to_json)

      stub_request(:post, uri)
        .with(body: request_body.to_json)
        .to_return(body: { result: txid,
                           error: nil,
                           id: 1 }.to_json)
      result = wallet.create_transaction!(transaction)
      expect(result.as_json.symbolize_keys).to eq(amount: 1.1.to_s,
                                                  to_address: '0x6d6cabaa7232d7f45b143b445114f7e92350a2aa',
                                                  hash: txid,
                                                  status: 'pending',
                                                  options: { 'erc20_contract_address' => '0x87099add3bcc0821b5b151307c147215f839a110', 'gas_limit' => 90_000, 'gas_price' => 1_000_000_000 })
    end
  end

  #context :prepare_deposit_collection! do
  #let(:value) { '0xa3b5840f4000' }

  #let(:gas_price) { 1_000_000_000 }
  #let(:gas_price_hex) { '0x' + gas_price.to_s(16) }

  #let(:request_body) do
  #{ jsonrpc: '2.0',
  #id: 2,
  #method: :personal_sendTransaction,
  #params: [{
  #from: fee_wallet.address.downcase,
  #to: '0x6d6cabaa7232d7f45b143b445114f7e92350a2aa',
  #value: value,
  #gas: '0x5208',
  #gasPrice: '0x3b9aca00'
  #}, secret] }
  #end

  #let(:spread_deposit) do
  #[{ to_address: 'fake-hot',
  #amount: '2.0',
  #currency_id: trst.id },
  #{ to_address: 'fake-hot',
  #amount: '2.0',
  #currency_id: trst.id }]
  #end

  #let(:settings) do
  #{
  #wallet: fee_wallet.to_wallet_api_settings,
  #currency: eth.to_blockchain_api_settings.merge(min_collection_amount: '1.0')
  #}
  #end

  #before do
  #wallet.configure(settings)
  #end

  #it do
  #txid = '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017'

  #stub_request(:post, uri)
  #.with(body: eth_GasPrice.to_json)
  #.to_return(body: { result: gas_price_hex,
  #error: nil,
  #id: 1 }.to_json)

  #stub_request(:post, uri)
  #.with(body: request_body.to_json)
  #.to_return(body: { result: txid,
  #error: nil,
  #id: 1 }.to_json)
  #result = wallet.prepare_deposit_collection!(transaction, spread_deposit, trst.to_blockchain_api_settings)
  #expect(result.first.as_json.symbolize_keys).to eq(amount: '0.00018',
  #currency_id: 'eth',
  #to_address: '0x6d6cabaa7232d7f45b143b445114f7e92350a2aa',
  #hash: txid,
  #status: 'pending',
  #options: {"gas_limit"=>21000, "gas_price"=>1000000000})
  #end

  #context 'erc20_contract_address is not configured properly in currency' do
  #it 'returns empty array' do
  #currency = trst.to_blockchain_api_settings.deep_dup
  #currency[:options].delete(:erc20_contract_address)
  #expect(wallet.prepare_deposit_collection!(transaction, spread_deposit, currency)).to eq []
  #end
  #end

  #context '#calculate_gas_price' do
  #let(:gas_price) { 1_000_000_000 }
  #let(:gas_price_hex) { '0x' + gas_price.to_s(16) }

  #let(:settings) do
  #{
  #wallet: fee_wallet.to_wallet_api_settings,
  #currency: eth.to_blockchain_api_settings
  #}
  #end

  #let(:eth_GasPrice) do
  #{
  #"jsonrpc": '2.0',
  #"id": 1,
  #"method": 'eth_gasPrice',
  #"params": []
  #}
  #end

  #before do
  #wallet.configure(settings)
  #stub_request(:post, uri)
  #.with(body: eth_GasPrice.to_json)
  #.to_return(body: { result: gas_price_hex,
  #error: nil,
  #id: 1 }.to_json)
  #end

  #it do
  #options = { gas_price: 'standard' }
  #expect(wallet.send(:calculate_gas_price, options)).to eq gas_price
  #end

  #it do
  #options = { gas_price: 'fast' }
  #expect(wallet.send(:calculate_gas_price, options)).to eq gas_price * 1.1
  #end

  #it do
  #options = { gas_price: 'safelow' }
  #expect(wallet.send(:calculate_gas_price, options)).to eq gas_price * 0.9
  #end

  #it do
  #options = { gas_price: 12_346_789.to_s(16) }
  #expect(wallet.send(:calculate_gas_price, options)).to eq gas_price
  #end

  #it do
  #expect(wallet.send(:calculate_gas_price)).to eq gas_price
  #end

  #it do
  #expect(wallet.send(:calculate_gas_price, {})).to eq gas_price
  #end
  #end

  #context 'unsuccessful' do
  #let(:settings) do
  #{
  #wallet: fee_wallet.to_wallet_api_settings,
  #currency: eth.to_blockchain_api_settings
  #}
  #end

  #before do
  #wallet.configure(settings)
  #end

  #it 'should raise an error' do
  #txid = '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017'

  #stub_request(:post, uri)
  #.with(body: eth_GasPrice.to_json)
  #.to_return(body: { result: gas_price_hex,
  #error: nil,
  #id: 1 }.to_json)

  #stub_request(:post, uri)
  #.with(body: request_body.to_json)
  #.to_return(body: { result: txid,
  #error: nil,
  #id: 1 }.to_json)
  #expect {
  #wallet.prepare_deposit_collection!(transaction, spread_deposit, trst.to_blockchain_api_settings)
  #}.to raise_error(Peatio::Wallet::ClientError)
  #end
  #end
  #end
end
