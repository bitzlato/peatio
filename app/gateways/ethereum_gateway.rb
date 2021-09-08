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

  def has_enough_gas?(address)
    address = address.address if address.is_a? PaymentAddress
    fetch_gas(address) >= fetch_native_balance(address)
  end

  def fetch_gas(address)
    address = address.address if address.is_a? PaymentAddress
    ac = AbstractCommand.new(client)
    gas_price = ac.fetch_gas_price
    ac.estimage_gas(gas_price: gas_price, from: address, to: hot_wallet.address) * gas_price
  end

  def fetch_native_balance(address)
    address = address.address if address.is_a? PaymentAddress
    load_balances(address).fetch(blockchain.native_currency.id, 0)
  end

  def refuel_and_collect!(payment_address)
    refuel_gas!(payment_address)
    # TODO подождать пока транзакция придет
    sleep 60
    collect!(payment_address)
  end

  # Collect all tokens and coins from payment_address to hot wallet
  def collect!(payment_address, skip_gas_checking: false)
    raise 'wrong blockchain' unless payment_address.blockchain_id == blockchain.id

    balances = load_balances(payment_address.address).
      reject { |c, a| a.zero? }.
      transform_keys { |k| blockchain.currencies.find_by(id: k) || raise("Unknown currency in balance #{k} for #{blockchain.key}") }.
      compact

    unless skip_gas_checking
      raise 'has no enough gas' unless fetch_gas(payment_address.address) >= balances[blockchain.native_currency]
    end

    # First collect tokens (save base currency to last step for gas)
    token_currencies = balances.filter { |c| c.token? }.keys
    base_currencies = balances.reject { |c| c.token? }.keys

    # TODO Сообщать о том что не хватает газа ДО выполнения, так как он потратися
    # Не выводить базовую валюту пока не счету есть токены
    # Базовую валюту откидывать за вычетом необходимой суммы газа для токенов
    (token_currencies + base_currencies).map do |currency|
      amount = balances.fetch(currency)
      next if amount.zero?

      # Skip base currency collection until we have tokens on balance. To have enough gase
      next if base_currencies.include?(currency) && token_currencies.any?

      # TODO Пропускать если стоимость монет меньше чем стоимость газа X2
      logger.info("Collect #{currency.id} #{amount} from #{payment_address.address} to #{hot_wallet.address}")
      transaction = create_transaction!(
        from_address: payment_address.address,
        to_address: hot_wallet.address,
        amount: amount,
        secret: payment_address.secret,
        contract_address: currency.contract_address,
        subtract_fee: currency.contract_address.nil?
      )
      logger.info("Collect transaction created #{transaction.as_json}")
      transaction.txid
      # TODO Save CollectRecord with transaction dump
    rescue EthereumGateway::TransactionCreator::Error => err
      report_exception err, true, payment_address_id: payment_address.id, currency: currency
      logger.warn("Errored collecting #{currency} #{amount} from address #{payment_address.address} with #{err}")
      nil
    end.compact

    # 1. Check transaction status in blockchain or transactions network.
    # 2. Create transactions from from_address to to_address for all existen coins
  end

  def refuel_gas!(target_address)
    target_address = target_address.address if target_address.is_a? PaymentAddress

    tokens = load_balances(target_address)
      .select { |_currency, balance| balance.positive? }
      .transform_keys { |k| blockchain.currencies.find_by(id: k) || raise("Unknown currency in balance #{k} for #{blockchain.key}") }
      .select { |currency, _balance| currency.token? }
      .count
    logger.info("Refuel #{target_address} for #{tokens.join(',')} tokens")
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
        contract_addresses: tokens.map(&:contract_address)
      )
    )

    logger.info("#{target_address} refueled with transaction #{transaction.as_json}")

    transaction
    # TODO save GasRefuel record as reference

  rescue EthereumGateway::GasRefueler::Error => err
    report_exception err, true, target_address: target_address, blockchain_key: blockchain.key
    logger.info("Canceled refueling address #{target_address} with #{err}")
  end

  def has_enough_gas?(from_address, to_address)
  end

  def require_gas_refueling?(address)
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
    blockchain.
      wallets.
        active.
        hot.
        take|| raise(NoHotWallet)
  end

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
