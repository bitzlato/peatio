# frozen_string_literal: true

describe ::EthereumGateway::GasRefueler do
  subject { described_class.new(ethereum_client) }

  let(:eth) { Currency.find_by(id: :eth) }
  let(:result) do
    subject.call(
      gas_factor: refuel_gas_factor,
      gas_wallet_address: from_address,
      gas_wallet_secret: secret,
      target_address: to_address,
      contract_addresses: contract_addresses,
      gas_price: gas_price,
      gas_limits: gas_limits
    )
  end
  let(:trst) { Currency.find_by(id: :trst) }
  let(:secret) { SecureRandom.hex(5) }
  let(:txid) { '0xab6ada9608f4cebf799ee8be20fe3fb84b0d08efcdb0d962df45d6fce70cb017' }
  let(:gas_price) { 1_000_000_000 }
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }
  let(:refuel_gas_factor) { 1 }

  before do
    stub_balance_fetching blockchain_currency: eth.blockchain_currencies[0], balance: balance_on_target_address, address: to_address
    stub_gas_fetching gas_price: gas_price, id: 2
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context 'address has no tokens' do
    let(:contract_addresses) { [] }
    let(:gas_limits) { {} }

    context 'it has zero ethereum balance' do
      let(:balance_on_target_address) { 0 }

      it { expect { result }.to raise_error described_class::NoTokens }
    end

    context 'it has small ethereum balance' do
      let(:balance_on_target_address) { 10_000 }

      it { expect { result }.to raise_error described_class::NoTokens }
    end

    context 'it has big ethereum balance' do
      let(:balance_on_target_address) { 10**18 }

      it { expect { result }.to raise_error described_class::NoTokens }
    end
  end

  context 'address has tokens' do
    let(:balance_on_target_address) { 0 }
    let(:eth_blockchain_currency) { eth.blockchain_currencies[0] }
    let(:trst_blockchain_currency) { trst.blockchain_currencies[0] }
    let(:contract_addresses) { [trst_blockchain_currency.contract_address] }
    let(:gas_limits) { { nil => eth_blockchain_currency.gas_limit, trst_blockchain_currency.contract_address => trst_blockchain_currency.gas_limit } }
    let(:estimated_gas) { eth_blockchain_currency.gas_limit }
    let(:gas_limit) { estimated_gas }

    context 'and it has no enough ethereum balance' do
      before do
        stub_personal_send_transaction(
          value: value,
          from_address: from_address,
          secret: secret,
          to_address: to_address,
          gas: eth_blockchain_currency.gas_limit,
          gas_price: transaction_gas_price,
          txid: txid,
          id: 2
        )
      end

      let(:balance_on_target_address) { 10_000 }
      let(:value) { ((trst_blockchain_currency.gas_limit * transaction_gas_price) + (eth_blockchain_currency.gas_limit * transaction_gas_price)).to_i - balance_on_target_address }
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
            'gas_limit' => gas_limit,
            'gas_price' => transaction_gas_price,
            'subtract_fee' => false,
            'required_amount' => 111_000_000_000_000,
            'required_gas' => trst_blockchain_currency.gas_limit
          }
        }
      end

      it { expect(result.as_json.symbolize_keys).to eq(result_transaction_hash) }
    end

    context 'and it has enough ethereum balance' do
      let(:balance_on_target_address) { 10**18 }

      it { expect { result }.to raise_error described_class::Balanced }
    end
  end
end
