# Proxy to Ethereum.
#
# Converts amounts from money to ethereum base units.
# Knows about peatio database models.
#
class EthereumGateway < AbstractGateway
  include NumericHelpers
  IDLE_TIMEOUT = 1

  def self.valid_address?(address)
    AdequateCryptoAddress.valid? address, :ethereum
  end

  def self.normalize_address(address)
    AdequateCryptoAddress.address(address, :eth).address
  end

  def self.normalize_txid(id)
    id.downcase
  end

  def enable_block_fetching?
    true
  end

  def refuel_and_collect!(payment_address)
    refuel_gas!(payment_address.address)
    # TODO подождать пока транзакция придет
    sleep 60
    collect!(payment_address)
  end

  # Collect all tokens and coins from payment_address to hot wallet
  def collect!(payment_address)
    hot_wallet = blockchain.hot_wallet || raise("No hot wallet for blockchain #{blockchain.id}")

    balances = load_balances(payment_address.address).reject { |c, a| a.zero? }

    # First collect tokens (save base currency to last step for gas)
    token_currencies = balances.filter { |c| c.token? }.keys
    base_currencies = balances.reject { |c| c.token? }.keys
    base_currencies = [] if Rails.env.production? # TODO

    # TODO Сообщать о том что не хватает газа ДО выполнения, так как он потратися
    # Не выводить базовую валюту пока не счету есть токены
    # Базовую валюту откидывать за вычетом необходимой суммы газа для токенов
    (token_currencies + base_currencies).map do |currency|
      amount = balances[currency]
      next if amount.zero?
      logger.info("Collect #{currency} #{amount} from #{payment_address.address} to #{hot_wallet.address}")
      transaction = monefy_transaction(
        TransactionCreator
        .new(client)
        .call(from_address: payment_address.address,
              to_address: hot_wallet.address,
              amount: amount.base_units,
              secret: payment_address.secret,
              contract_address: currency.contract_address,
              subtract_fee: currency.contract_address.nil?)
      )
      Transaction.upsert_transaction! transaction
    rescue EthereumGateway::TransactionCreator::Error => err
      logger.warn("Errored collecting #{currency} #{amount} from address #{payment_address.address} with #{err}")
      nil
    end.compact

    # 1. Check transaction status in blockchain or transactions network.
    # 2. Create transactions from from_address to to_address for all existen coins
  end

  def refuel_gas!(target_address)
    target_address = target_address.address if target_address.is_a? PaymentAddress
    gas_wallet = blockchain.fee_wallet || raise("No fee wallet for blockchain #{blockchain.id}")

    tokens_count = load_balances(target_address)
      .select { |currency, balance| currency.token? && balance.positive? }
      .count
    transaction = monefy_transaction(
      EthereumGateway::GasRefueler
      .new(client)
      .call(
        gas_wallet_address: gas_wallet.address,
        gas_wallet_secret: gas_wallet.secret,
        target_address: target_address,
        tokens_count: tokens_count,
      )
    )

    logger.info("#{target_address} refueled with transaction #{transaction.as_json}")
    # TODO save GasRefuel record as reference
    Transaction.upsert_transaction! transaction, options: { tokens_count: tokens_count }

  rescue EthereumGateway::GasRefueler::Error => err
    logger.info("Canceled refueling address #{target_address} with #{err}")
  end

  def load_balances(address)
    blockchain.currencies.each_with_object({}) do |currency, a|
      a[currency.money_currency] = load_balance(address, currency)
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
                          subtract_fee: false)


    raise 'amount must be a Money' unless amount.is_a? Money
    # TODO save transaction
    monefy_transaction(
      TransactionCreator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            amount: amount.base_units,
            secret: secret,
            contract_address: contract_address,
            subtract_fee: subtract_fee)
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
  rescue Ethereum::Client::Error => e
    raise Peatio::Blockchain::ClientError, e
  end

  def fetch_transaction(txid, txout = nil)
    monefy_transaction(
      TransactionFetcher.new(client).call(txid, txout)
    )
  end

  private

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
