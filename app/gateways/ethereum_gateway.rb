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

  # Collect all tokens and coins from payment_address to hot wallet
  def collect!(payment_address)
    hot_wallet = blockchain.hot_wallet || raise("No hot wallet for blockchain #{blockchain.id}")

    # TODO refuel if need?
    load_balances(payment_address.address).each_pair do |currency, amount|
      hash_to_transaction(
        TransactionCreator
        .new(client)
        .call(from_address: payment_address.address,
              to_address: hot_wallet.address,
              amount: amount.base_units,
              secret: payment_address.secret,
              contract_address: currency.contract_address,
              subtract_fee: true)
      )
    rescue EthereumGateway::TransactionCreator::Error => err
      logger.warn("Errored collecting #{currency} #{amount} from address #{payment_address.address} with #{err}")
    end

    # 1. Check transaction status in blockchain or transactions network.
    # 2. Create transactions from from_address to to_address for all existen coins

  end

  def refuel_gas!(target_address)
    gas_wallet = blockchain.fee_wallet || raise("No fee wallet for blockchain #{blockchain.id}")

    tokens_count = load_balances(target_address)
      .select { |currency, balance| currency.token? && balance.positive? }
      .count
    transaction = hash_to_transaction(
      EthereumGateway::GasRefueler
      .new(client)
      .call(
        gas_wallet_address: gas_wallet.address,
        gas_wallet_secret: gas_wallet.secret,
        target_address: target_address,
        tokens_count: tokens_count,
      )
    )

    logger.info("#{target_address} refueled with transaction #{transaction}")
    # TODO save GasRefuel record as reference
    save_transaction transaction, options: { tokens_count: tokens_count, ethereum_balance: ethereum_balance }

  rescue EthereumGateway::GasRefueler::Error => err
    logger.info("Canceled refueling address #{target_address} with #{err}")
  end

  def load_balances(address)
    blockchain.currencies.each_with_object({}) do |currency, a|
      a[currency] = load_balance(address, currency)
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
    hash_to_transaction(
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

  def collect_deposit!(deposit)
    DepositCollector
      .new(client)
      .call(deposit)
  end

  #def process_block(block_number)
    #amount_converter = -> (amount, contract_address = nil) do
      #(
        #blockchain.
        #currencies.
        #map(&:money_currency).
        #find { |mc| mc.contract_address.presence == contract_address.presence } ||
        #binding.pry
        #raise("No found currency for #{contract_address} in blockchain #{blockchain}")
      #).
        #to_money(amount)
    #end
    #BlockProcessor
      #.new(client)
      #.call(block_number,
            #contract_addresses: blockchain.currencies.tokens.map(&:contract_address),
            #system_addresses: blockchain.wallets.pluck(:address).compact,
            #allowed_contracts: blockchain.whitelisted_smart_contracts.active,
            #withdraw_checker: -> (address) { Wallet.withdraw.where(address: address).present? },
            #deposit_checker: -> (address) { PaymentAddress.where(address: address).present? },
            #amount_converter: amount_converter
           #)
  #end

  def fetch_block_transactions(block_number)
    BlockFetcher
      .new(client)
      .call(block_number,
            contract_addresses: blockchain.contract_addresses,
            follow_addresses: blockchain.follow_addresses,
            follow_txids: blockchain.follow_txids)
      .map(&method(:hash_to_transaction))
  end

  def latest_block_number
    client.json_rpc(:eth_blockNumber).to_i(16)
  rescue Ethereum::Client::Error => e
    raise Peatio::Blockchain::ClientError, e
  end

  def fetch_transaction(txid, txout = nil)
    hash_to_transaction(
      TransactionFetcher.new(client).call(txid, txout)
    )
  end

  private

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
