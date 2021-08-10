class EthereumGateway < AbstractGateway
  IDLE_TIMEOUT = 1

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

  def create_transaction!(from_address:, to_address:, amount:, secret: , contract_address: nil, subtract_fee: false)
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

  def fetch_block(block_number)
    BlockFetcher
      .new(client)
      .call(block_number)
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
