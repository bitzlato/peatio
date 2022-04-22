# frozen_string_literal: true

# Proxy to Ethereum.
#
# Converts amounts from money to ethereum base units.
# Knows about peatio database models.
#
class EthereumGateway < AbstractGateway
  include NumericHelpers
  extend Concern
  include CollectionConcern
  include BalancesConcern
  include EstimationGasConcern

  IDLE_TIMEOUT = 1

  Error = Class.new StandardError
  NoHotWallet = Class.new Error

  def self.address_type
    :ethereum
  end

  def self.private_key(private_key_hex)
    Eth::Key.new(priv: private_key_hex)
  end

  def enable_block_fetching?
    true
  end

  # Returns SemVer object of client's version
  def client_version
    AbstractCommand.new(client).client_version
  end

  def create_address!(secret = nil)
    if ENV.true?('USE_PRIVATE_KEY')
      create_private_address!
    else
      create_personal_address!(secret)
    end
  end

  def create_transaction!(from_address:,
                          to_address:,
                          amount:,
                          secret:,
                          blockchain_address: nil,
                          contract_address: nil,
                          subtract_fee: false, # nil means auto
                          nonce: nil,
                          gas_factor: nil,
                          meta: {}) # rubocop:disable Lint/UnusedMethodArgument

    raise 'amount must be a Money' unless amount.is_a? Money

    gas_factor = gas_factor || blockchain.client_options[:gas_factor].to_d || 1
    gas_factor = 1.01 if gas_factor.to_d < 1
    gas_price = (AbstractCommand.new(client).fetch_gas_price * gas_factor).to_i
    gas_limit ||= estimated_gas(contract_addresses: [contract_address].compact,
                                account_native: contract_address.nil?,
                                gas_limits: gas_limits)
    monefy_transaction(
      TransactionCreator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            amount: amount.base_units,
            secret: secret,
            blockchain_address: blockchain_address,
            gas_limit: gas_limit,
            gas_price: gas_price,
            contract_address: contract_address,
            subtract_fee: subtract_fee.nil? ? contract_address.nil? : subtract_fee,
            nonce: nonce,
            chain_id: blockchain.chain_id)
    )
  end

  def self.supports_allowance?
    true
  end

  def approve!(address:, secret:, spender_address:, contract_address:, nonce: nil, gas_factor: nil)
    gas_factor = gas_factor || blockchain.client_options[:gas_factor].to_d || 1
    gas_factor = 1.01 if gas_factor.to_d < 1
    gas_price = (AbstractCommand.new(client).fetch_gas_price * gas_factor).to_i
    gas_limit ||= estimated_gas(contract_addresses: [contract_address].compact,
                                account_native: false,
                                gas_limits: gas_limits)
    Approver.new(client).call(from_address: address, spender: spender_address, secret: secret, gas_limit: gas_limit, contract_address: contract_address, nonce: nonce, gas_price: gas_price)
  end

  def fetch_block_transactions(block_number)
    BlockFetcher
      .new(client)
      .call(block_number,
            contract_addresses: blockchain.contract_addresses,
            follow_addresses: blockchain.follow_addresses,
            follow_txids: blockchain.follow_txids.presence,
            whitelisted_addresses: blockchain.whitelisted_addresses)
      .map(&method(:monefy_transaction))
  end

  def latest_block_number
    client.json_rpc(:eth_blockNumber).to_i(16)
  end

  def fetch_transaction(txid, _txout = nil)
    monefy_transaction(
      TransactionFetcher.new(client).call(txid)
    )
  end

  private

  def create_private_address!
    key = Eth::Key.new
    blockchain_address = BlockchainAddress.create!(address: key.address, address_type: 'ethereum', private_key_hex: key.private_hex)

    { address: blockchain_address.address }
  end

  def create_personal_address!(secret = nil)
    AddressCreator
      .new(client)
      .call(secret)
  end

  def gas_limits
    blockchain.blockchain_currencies.each_with_object({}) { |bc, agg| agg[bc.contract_address] = bc.gas_limit }
  end

  def fee_wallet
    blockchain.fee_wallet || raise("No fee wallet for blockchain #{blockchain.id}")
  end

  def hot_wallet
    blockchain.hot_wallet || raise(NoHotWallet)
  end

  def build_client
    client_options = (blockchain.client_options || {}).symbolize_keys
                                                      .slice(:idle_timeout, :read_timeout, :open_timeout)
                                                      .reverse_merge(idle_timeout: IDLE_TIMEOUT)

    ::Ethereum::Client.new(blockchain.server, **client_options)
  end
end
