# Proxy to Ethereum.
#
# Converts amounts from money to ethereum base units.
# Knows about peatio database models.
#
class EthereumGateway < AbstractGateway
  include NumericHelpers
  extend Concern
  IDLE_TIMEOUT = 1

  Error = Class.new StandardError
  NoHotWallet = Class.new Error

  def enable_block_fetching?
    true
  end

  # Returns SemVer object of client's version
  def client_version
    AbstractCommand.new(client).client_version
  end

  def fetch_gas(address)
    address = address.address if address.is_a? PaymentAddress
    ac = AbstractCommand.new(client)
    gas_price = ac.fetch_gas_price
    ac.estimage_gas(gas_price: gas_price, from: address, to: hot_wallet.address) * gas_price
  end

  def fetch_balance
    address = address.address if address.is_a? PaymentAddress
    blockchain.native_currency.to_money_from_units(
      AbstractCommand.new(client).load_basic_balance
    )
  end

  def collect!(payment_address)
    raise 'wrong blockchain' unless payment_address.blockchain_id == blockchain.id
    amounts = load_balances(payment_address.address)
      .select { |currency, amount| is_balance_collectable?(amount, currency, payment_address.address) }
      .transform_values { |v| v.base_units }
      .transform_keys { |c| c.contract_address }

    # Remove native currency if there are tokens to transfer
    amounts.delete nil if amounts.many?

    logger.info("Collect from payment_address #{payment_address} amounts: #{amounts}")
    EthereumGateway::Collector
      .new(client)
      .call(from_address: payment_address.address,
            to_address: hot_wallet.address,
            amounts: amounts,
            gas_factor: blockchain.client_options[:gas_factor],
            secret: payment_address.secret) if amounts.any?
  end

  def refuel_gas!(target_address)
    target_address = target_address.address if target_address.is_a? PaymentAddress

    contract_addresses = select_collectable_contract_addresses traget_address

    logger.info("Refuel #{target_address} for #{contract_addresses.join(',')} contract_addresses")
    transaction = monefy_transaction(
      EthereumGateway::GasRefueler
      .new(client)
      .call(
        gas_factor: blockchain.client_options[:gas_factor],
        base_gas_limit: blockchain.client_options[:base_gas_limit],
        token_gas_limit: blockchain.client_options[:token_gas_limit],
        gas_wallet_address: fee_wallet.address,
        gas_wallet_secret: fee_wallet.secret,
        target_address: target_address,
        contract_addresses: contract_addresses
      )
    )

    logger.info("#{target_address} refueled with transaction #{transaction.as_json}")

    transaction
    # TODO save GasRefuel record as reference

  rescue EthereumGateway::GasRefueler::Error => err
    report_exception err, true, target_address: target_address, blockchain_key: blockchain.key
    logger.info("Canceled refueling address #{target_address} with #{err}")
  end

  def has_enough_gas_to_collect?(address)
    fetch_balance >= GasEstimator
      .new(client)
      .call(from_address: address, to_addresses: [hot_wallet.address] + select_collectable_contract_addresses(address))
  end

  def collectable_balance?(address)
    select_collectable_contract_addresses(address).any? ||
      fetch_balance > GasEstimatonew(client).call(from_address: address, to_addresses: [hot_wallet.address])
  end

  def select_collectable_contract_addresses(address)
     blockchain
      .currencies
      .select(&:token?)
      .select { |currency| is_balance_collectable?(load_balance(address, currency), currency, address) }
      .map(&:contract_address)
  end

  def is_balance_collectable?(amount, currency, address)
    if currency == blockchain.native_currency
      amount >= GasEstimator
        .new(client)
        .call(from_address: address, to_addresses: [hot_wallet.address])
    else
      # TODO Учитывать цену токена для сбора, она должна быть выше затрачиваемого газа
      amount.positive?
    end
  end

  def load_balances(address)
    blockchain.currencies.each_with_object({}) do |currency, a|
      a[currency.id] = load_balance(address, currency)
    end
  end

  # @return balance of addrese in Money
  def load_balance(address, currency)
    BalanceLoader
      .new(client)
      .call(address, currency.contract_address)
      .yield_self { |amount| currency.to_money_from_units(amount) }
  end

  def create_address!(secret = nil)
    AddressCreator
      .new(client)
      .call(secret)
  end

  def create_transaction!(from_address:,
                          to_address:,
                          amount:,
                          secret:,
                          contract_address: nil,
                          subtract_fee: false, # nil means auto
                          nonce: nil,
                          meta: {})

    raise 'amount must be a Money' unless amount.is_a? Money
    # If gas_limit is nil it will be estimated by eth_estimateGas
    gas_limit = amount.currency.token? ? blockchain.client_options[:token_gas_limit] : blockchain.client_options[:base_gas_limit]
    monefy_transaction(
      TransactionCreator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            amount: amount.base_units,
            secret: secret,
            gas_limit: gas_limit,
            gas_factor: blockchain.client_options[:gas_factor] || 1,
            contract_address: contract_address,
            subtract_fee: subtract_fee.nil? ? contract_address.nil? : subtract_fee,
            nonce: nonce
           )
    )
  end

  def fetch_gas_price
    blockchain.fee_currency.to_money_from_units(
      AbstractCommand.new(client).fetch_gas_price
    )
  end

  def fetch_block_transactions(block_number)
    BlockFetcher
      .new(client)
      .call(block_number,
            contract_addresses: blockchain.contract_addresses,
            follow_addresses: blockchain.follow_addresses,
            follow_txids: blockchain.follow_txids.presence)
      .map(&method(:monefy_transaction))
  end

  def latest_block_number
    client.json_rpc(:eth_blockNumber).to_i(16)
  end

  def fetch_transaction(txid, txout = nil)
    monefy_transaction(
      TransactionFetcher.new(client).call(txid, txout)
    )
  end

  def current_syncing_block
    client.json_rpc(:eth_syncing).fetch('currentBlock').to_i(16)
  end

  private

  def fee_wallet
    blockchain.fee_wallet || raise("No fee wallet for blockchain #{blockchain.id}")
  end

  def hot_wallet
    blockchain.hot_wallet || raise(NoHotWallet)
  end

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
