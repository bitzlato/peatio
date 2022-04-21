# frozen_string_literal: true

require 'belomor_client'

class BelomorGateway < AbstractGateway
  def create_address!(owner_id:)
    client.create_address(owner_id: owner_id)
  end

  def client_version
    client.client_version.fetch('client_version')
  end

  def latest_block_number
    client.latest_block_number.fetch('latest_block_number')
  end

  def load_balances(address)
    balances = client.address(address).fetch('balances')
    balances.each do |currency_id, value|
      blockchain_currency = BlockchainCurrency.find_by!(currency_id: currency_id, blockchain: blockchain)
      balances[currency_id] = blockchain_currency.money_currency.to_money_from_decimal(value.to_d)
    end
    balances
  end

  def create_transaction!(from_address:, to_address:, amount:, blockchain_address: nil, contract_address: nil, subtract_fee: false, nonce: nil, gas_factor: nil, meta: {})  # rubocop:disable Lint/UnusedMethodArgument
    currency_id = BlockchainCurrency.find_by!(blockchain: blockchain, contract_address: contract_address).currency_id

    result = client.create_transaction(from_address: from_address, to_address: to_address, amount: amount, currency_id: currency_id)

    blockchain_currency = BlockchainCurrency.find_by!(blockchain: blockchain, currency_id: result['currency_id'])
    amount = blockchain_currency.money_currency.to_money_from_decimal(result['amount'].to_d).base_units
    monefy_transaction(
      from_address: from_address,
      to_address: result['address'],
      amount: amount,
      hash: result['txid'],
      contract_address: blockchain_currency.contract_address
    )
  end

  private

  def build_client
    BelomorClient.new(api_url: blockchain.server, blockchain_key: blockchain.key)
  end
end
