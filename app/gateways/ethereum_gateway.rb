class EthereumGateway < AbstractGateway
  IDLE_TIMEOUT = 1

  def enable_block_fetching?
    true
  end

  def load_balance(address, currency)
    BalanceLoader
      .new(client)
      .call(address, currency.base_factor, currency.contract_address)
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
    t = TransactionCreator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            amount: amount.base_units,
            secret: secret,
            contract_address: contract_address,
            subtract_fee: subtract_fee)

    return unless t
    t.amount =  amount.currency.to_money_from_units(t.amount)
    t
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

  def hash_to_transaction(hash)
    currency = blockchain.find_money_currency(hash.fetch(:contract_address))
    Peatio::Transaction.new hash.merge(currency_id: currency.id, amount: currency.to_money_from_units(hash.fetch(:amount)))
  end

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
