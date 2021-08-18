# Proxy to Ethereum.
#
# Converts amounts from money to ethereum base units.
# Knows about peatio database models.
#
class EthereumGateway < AbstractGateway
  include NumericHelpers
  IDLE_TIMEOUT = 1

  def enable_block_fetching?
    true
  end

  # Collect all tokens and coins from from_address to to_address
  def collect!(from_address:, to_address:)
    raise 'not implemented'

    refuel_gas! from_address

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
    transaction['txid'] = transaction.delete('hash')
    reference = nil # TODO create GasRefuel record
    Transaction.create!(transaction.merge(reference: reference, options: { tokens_count: tokens_count, ethereum_balance: ethereum_balance }))

  rescue EthereumGateway::GasRefueler::Error => err
    logger.info("Canceled refueling address #{target_address} with #{err}")
  end

  def load_balances(address)
    blockchain.currencies.each_with_object({}) do |currency, a|
      a[currency] = load_balance(address, currency)
    end
  end

  def load_balance(address, currency)
    BalanceLoader
      .new(client)
      .call(address, currency.contract_address)
      .yield_self { |amount| convert_from_base_unit(amount, currency.base_factor) }
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

  def logger
    Rails.logger
  end

  def hash_to_transaction(hash)
    return if hash.nil?
    if hash.is_a? Peatio::Transaction
      currency = blockchain.find_money_currency(hash.contract_address)
      hash.dup.tap do |t|
        t.currency_id = currency.id
        t.amount = currency.to_money_from_units hash.amoount
      end.freeze
    else
      currency = blockchain.find_money_currency(hash.fetch(:contract_address))
      Peatio::Transaction.new(hash.merge(currency_id: currency.id, amount: currency.to_money_from_units(hash.fetch(:amount)))).freeze
    end
  end

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
