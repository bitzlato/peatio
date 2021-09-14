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

  IDLE_TIMEOUT = 1

  Error = Class.new StandardError
  NoHotWallet = Class.new Error
  NoAddressesToEstimate = Class.new Error

  def enable_block_fetching?
    true
  end

  # Returns SemVer object of client's version
  def client_version
    AbstractCommand.new(client).client_version
  end

  # Выбирает на адресе монеты которые можно вывести (их баланс больше суммы газа который потребуется для вывода)
  # Вычисляет сколько нужно газа чтобы их вывести и закидывает его на баланс ардеса с горячего кошелька
  def refuel_gas!(target_address)
    target_address = target_address.address if target_address.is_a? PaymentAddress

    coins = collectable_coins target_address

    logger.info("Refuel #{target_address} for coins #{coins.map { |c| c || :native }.join(',')}")
    transaction = monefy_transaction(
      EthereumGateway::GasRefueler
      .new(client)
      .call(
        gas_factor: blockchain.client_options[:gas_factor],
        gas_wallet_address: fee_wallet.address,
        gas_wallet_secret: fee_wallet.secret,
        target_address: target_address,
        contract_addresses: coins,
        gas_limits: gas_limits
      )
    )

    logger.info("#{target_address} refueled with transaction #{transaction.as_json}")

    transaction
    # TODO save GasRefuel record as reference

  rescue EthereumGateway::GasRefueler::Error => err
    report_exception err, true, target_address: target_address, blockchain_key: blockchain.key
    logger.info("Canceled refueling address #{target_address} with #{err}")
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
    gas_factor = blockchain.client_options[:gas_factor] || 1
    gas_price ||= (fetch_gas_price * gas_factor).to_i
    gas_limit ||= GasEstimator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            contract_addresses: [contract_address].compact,
            account_native: contract_addresses.nil?,
            gas_limits: gas_limits,
            gas_price: gas_price)

    monefy_transaction(
      TransactionCreator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            amount: amount.base_units,
            secret: secret,
            gas_price: gas_price,
            contract_address: contract_address,
            subtract_fee: subtract_fee.nil? ? contract_address.nil? : subtract_fee,
            nonce: nonce
           )
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

  def gas_limits
    blockchain.currencies.each_with_object({}) { |c, agg| agg[c.contract_address] = c.gas_limit }
  end

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
