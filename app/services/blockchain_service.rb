class BlockchainService
  Error = Class.new(StandardError)
  BalanceLoadError = Class.new(StandardError)

  attr_reader :blockchain, :whitelisted_smart_contract, :currencies, :adapter

  def initialize(blockchain)
    @blockchain = blockchain
    @currencies = blockchain.currencies.deposit_enabled
    @whitelisted_addresses = blockchain.whitelisted_smart_contracts.active
    @adapter = Peatio::Blockchain.registry[blockchain.client.to_sym].new
    @adapter.configure(server: @blockchain.server,
                       currencies: @currencies.map(&:to_blockchain_api_settings),
                       whitelisted_addresses: @whitelisted_addresses)
  end

  def implements?(method_name)
    @adapter.class.instance_methods(false).include?(method_name)
  end

  def latest_block_number
    @latest_block_number ||= @adapter.latest_block_number
  end

  def create_address!
    @adapter.class.create_address! blockchain.server
  end

  def case_sensitive?
    @adapter.features[:case_sensitive]
  end

  def supports_cash_addr_format?
    @adapter.features[:cash_addr_format]
  end

  def fetch_transaction(transaction)
    tx = Peatio::Transaction.new(currency_id: transaction.currency_id,
                                 hash: transaction.txid,
                                 to_address: transaction.rid,
                                 amount: transaction.amount)
    if @adapter.respond_to?(:fetch_transaction)
      @adapter.fetch_transaction(tx)
    else
      tx
    end
  end

  def process_block(block_number)
    block = gateway.fetch_block!(block_number)

    payment_addresses = PaymentAddress.where(blockchain: blockchain, address: block.transactions.map(&:to_address)).pluck(:address)
    withdraw_txids = Withdraws::Coin.confirming.where(currency: @currencies).pluck(:txid)

    block.select do |tx|
      if tx.to_address.in?(payment_addresses)
        update_or_create_deposit tx
      elsif tx.hash.in?(withdraw_txids)
        update_withdrawal tx
        withdrawals.each(&method(:update_withdrawal))
      end
      # TODO add blockchain
      Transaction
        .where(currency_id: tx.currency_id, txid: tx.hash)
        .where('fee is null or block_number is null')
        .update_all fee: tx.fee, block_number: tx.block_number
    end

    block
  end

  # Resets current cached state.
  def reset!
    @latest_block_number = nil
  end

  def update_fees!(block)
    block.each do |tx|
    end
  end

  def update_height(block_number)
    raise Error, "#{blockchain.name} height was reset." if blockchain.height != blockchain.reload.height

    # NOTE: We use update_column to not change updated_at timestamp
    # because we use it for detecting blockchain configuration changes see Workers::Daemon::Blockchain#run.
    blockchain.update_column(:height, block_number) if latest_block_number - block_number >= blockchain.min_confirmations
  end

  private

  def update_or_create_deposit(transaction)
    if transaction.amount < Currency.find(transaction.currency_id).min_deposit_amount
      # Currently we just skip tiny deposits.
      Rails.logger.info do
        "Skipped deposit with txid: #{transaction.hash} with amount: #{transaction.hash}"\
        " to #{transaction.to_address} in block number #{transaction.block_number}"
      end
      return
    end

    # Fetch transaction from a blockchain that has `pending` status.
    transaction = adapter.fetch_transaction(transaction) if @adapter.respond_to?(:fetch_transaction) && transaction.status.pending?
    return unless transaction.status.success?

    address = PaymentAddress.find_by(blockchain: blockchain, address: transaction.to_address)
    return if address.blank?

    # Skip deposit tx if there is tx for deposit collection process
    # TODO: select only pending transactions
    tx_collect = Transaction.where(txid: transaction.hash, reference_type: 'Deposit')
    return if tx_collect.present?

    if transaction.from_addresses.blank? && adapter.respond_to?(:transaction_sources)
      transaction.from_addresses = adapter.transaction_sources(transaction)
    end

    deposit =
      Deposits::Coin.find_or_create_by!(
        currency_id: transaction.currency_id,
        txid: transaction.hash,
        txout: transaction.txout
      ) do |d|
        d.address = transaction.to_address
        d.amount = transaction.amount
        d.member = address.member
        d.from_addresses = transaction.from_addresses
        d.block_number = transaction.block_number
      end

    unless deposit.block_number == transaction.block_number
      Rails.logger.warn { "Update deposit block_number (#{deposit.block_number} -> #{transaction.block_number}" }
      deposit.update_column :block_number, transaction.block_number
    end
    deposit.accept! if deposit.submitted?
    deposit.process! if latest_block_number - deposit.block_number >= blockchain.min_confirmations
  end

  def update_withdrawal(transaction)
    withdrawal = blockchain.withdraws.confirming
      .find_by(currency_id: transaction.currency_id, txid: transaction.hash)

    # Skip non-existing in database withdrawals.
    if withdrawal.blank?
      Rails.logger.info { "Skipped withdrawal: #{transaction.hash}." }
      return
    end

    withdrawal.with_lock do
      withdrawal.update_column :block_number, transaction.block_number if withdrawal.block_number.nil?

      # Fetch transaction from a blockchain that has `pending` status.
      transaction = adapter.fetch_transaction(transaction) if transaction.status.pending?

      # Manually calculating withdrawal confirmations, because blockchain height is not updated yet.
      if transaction.status.failed?
        withdrawal.fail!
      elsif transaction.status.success? && latest_block_number - withdrawal.block_number >= blockchain.min_confirmations
        withdrawal.success!
      end
    end
  end
end
