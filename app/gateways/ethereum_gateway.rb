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
    if amount.is_a? Money
      amount = amount.base_units
    elsif !amount.is_a? Integer
      raise "amount (#{amount} #{amount.class}) must be an Integer (base units)"
    end
    TransactionCreator
      .new(client)
      .call(from_address: from_address,
            to_address: to_address,
            amount: amount,
            secret: secret,
            contract_address: contract_address,
            subtract_fee: subtract_fee)
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

  def fetch_block(block_number)
    amount_converter = -> (amount, contract_address = nil) do
      (
        blockchain.
        currencies.
        map(&:money_currency).
        find { |mc| mc.contract_address.presence == contract_address.presence } ||
        raise("No found currency for #{contract_address} in blockchain #{blockchain}")
      ).
        to_money(amount)
    end
    BlockFetcher
      .new(client)
      .call(block_number,
            contract_addresses: blockchain.currencies.tokens.map(&:contract_address),
            system_addresses: blockchain.wallets.pluck(:address).compact,
            allowed_contracts: blockchain.whitelisted_smart_contracts.active,
            deposit_checker: -> (address) { PaymentAddress.where(address: address).present? },
            amount_converter: amount_converter
           )
  end

  def latest_block_number
    client.json_rpc(:eth_blockNumber).to_i(16)
  rescue Ethereum::Client::Error => e
    raise Peatio::Blockchain::ClientError, e
  end

  def fetch_transaction(txid, txout = nil)
    TransactionFetcher.new(client).call(txid, txout)
  end

  private

  def build_client
    ::Ethereum::Client.new(blockchain.server, idle_timeout: IDLE_TIMEOUT)
  end
end
