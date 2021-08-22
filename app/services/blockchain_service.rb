class BlockchainService
  Error = Class.new(StandardError)
  BalanceLoadError = Class.new(StandardError)

  attr_reader :blockchain, :whitelisted_smart_contract, :currencies

  delegate :gateway, to: :blockchain

  def initialize(blockchain)
    @blockchain = blockchain
    @currencies = blockchain.currencies.deposit_enabled
    @whitelisted_addresses = blockchain.whitelisted_smart_contracts.active
  end

  def latest_block_number
    @latest_block_number ||= gateway.latest_block_number
  end

  def update_transaction!(txid, txout = nil)
    blockchain_transaction = gateway.fetch_transaction txid, txout
    t = blockchain.transactions.find_by(txid: txid, txout: txout)
    # TODO lookup for reference if there are no transaction
    upsert_transaction! blockchain_transaction, t.try(:reference)
  end

  def process_block(block_number)
    dispatch_deposits! block_number

    transactions = gateway.fetch_block_transactions(block_number)

    withdraw_scope =  blockchain.withdraws.where.not(txid: nil).where(block_number: [nil,block_number])
    if Rails.env.production?
      withdraw_txids = withdraw_scope.confirming.pluck(:txid)
    else
      # Check it all, we want debug in development
      withdraw_txids = withdraw_scope.pluck(:txid)
    end

    transactions.each do |tx|
      @withdrawal = @deposit = @fetched_transaction = nil
      if tx.to_address.in?(blockchain.deposit_addresses)
        update_or_create_deposit tx
      elsif tx.hash.in?(withdraw_txids)
        update_or_create_withdraw tx
      end
      # TODO fetch_transaction if status is pending
      tx = fetch_transaction(tx)
      upsert_transaction! tx, (deposit || withdrawal)
    end.count
  end

  # Resets current cached state.
  def reset!
    @latest_block_number = nil
  end

  def update_height(block_number)
    raise Error, "#{blockchain.name} height was reset." if blockchain.height != blockchain.reload.height

    # NOTE: We use update_column to not change updated_at timestamp
    # because we use it for detecting blockchain configuration changes see Workers::Daemon::Blockchain#run.
    blockchain.update_column(:height, block_number) if latest_block_number - block_number >= blockchain.min_confirmations
  end

  private

  attr_reader :withdrawal, :deposit, :fetched_transaction

  def upsert_transaction!(tx, reference = nil)
    # TODO change currency_to blockchain_id
    t = Transaction.upsert!(
      fee: tx.fee,
      fee_currency_id: tx.fee_currency_id,
      block_number: tx.block_number,
      status: tx.status,
      txout: tx.txout,
      from_address: tx.from_address,
      amount: tx.amount,
      to_address: tx.to_address,
      currency_id: tx.currency_id,
      txid: tx.id,
      reference: reference
    )
    logger.debug("Transaction is saved to database with id=#{t.id}")
    t
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => err
    Bugsnag.notify err do |b|
      b.meta_data = { tx: tx, record: err.record.as_json }
    end
  end

  def dispatch_deposits! block_number
    blockchain.
      deposits.
      accepted.
      where('block_number <= ?', latest_block_number - blockchain.min_confirmations).
      lock.
      find_each do |deposit|
      logger.info("Dispatch deposit #{deposit.id}, confirmation #{latest_block_number - deposit.block_number}>=#{blockchain.min_confirmations}")
      deposit.dispatch!
    end
  end

  def update_or_create_deposit(transaction)
    address = PaymentAddress.find_by(blockchain: blockchain, address: transaction.to_address)

    # Not deposit address
    return if address.blank?

    if DepositSpread.find_by(txid: transaction.id).present?
      logger.debug("Catched spread transaction. Skip it #{transaction.id}")
      return
    end

    if transaction.amount < Currency.find(transaction.amount.currency.id).min_deposit_amount_money
      # Currently we just skip tiny deposits.
      logger.info do
        "Skipped deposit with txid: #{transaction.hash}"\
        " to #{transaction.to_address} in block number #{transaction.block_number}"\
        " because of low amount (#{transaction.amount.format} < #{Currency.find(transaction.amount.currency.id).min_deposit_amount_money.format})"
      end
      return
    end

    # Fetch transaction from a blockchain that has `pending` status.
    transaction = fetch_transaction(transaction)
    return unless transaction.status.success?

    # Skip deposit tx if there is tx for deposit collection process
    # TODO: select only pending transactions
    #tx_collect = blockchain.transactions.find_by(txid: transaction.id)
    #return if tx_collect.present?

    # Commented it out. Waiting to reproduce raise to check this kind of transactions
    #
    #if transaction.from_addresses.blank? && gateway.respond_to?(:transaction_sources)
      #transaction.from_addresses = gateway.transaction_sources(transaction)
    #end

    @deposit = Deposits::Coin.find_or_create_by!(
      currency_id: transaction.currency_id,
      txid: transaction.hash,
      txout: transaction.txout # what for? it is usable for blockchain only?
    ) do |d|
      d.address=transaction.to_address
      d.money_amount=transaction.amount
      d.member=address.member
      d.from_addresses=transaction.from_addresses.presence || raise("No transaction from_addresses")
      d.block_number=transaction.block_number || raise("Transaction #{transaction} has no block_number")
    end
    deposit.with_lock do
      if deposit.block_number.nil?
        logger.debug("Set block_number #{transaction.block_number} for deposit #{deposit.id}")
        deposit.update! block_number: transaction.block_number
      end
      raise "Amounts different #{deposit.id}" unless transaction.amount == deposit.money_amount
      logger.info("Found or created suitable deposit #{deposit.id} for txid #{transaction.id}, amount #{transaction.amount}")
      if deposit.submitted?
        logger.info("Accepting deposit #{deposit.id}")
        deposit.accept!
      end
    end
  end

  def update_or_create_withdraw(transaction)
    @withdrawal = blockchain.withdraws.confirming
      .find_by(currency_id: transaction.currency_id, txid: transaction.hash)

    # Skip non-existing in database withdrawals.
    if withdrawal.blank?
      logger.info { "Skipped withdrawal: #{transaction.hash}." }
      return
    end
    withdrawal.with_lock do
      withdrawal.update_column :block_number, transaction.block_number if withdrawal.block_number.nil?

      transaction = fetch_transaction(transaction)

      # Manually calculating withdrawal confirmations, because blockchain height is not updated yet.
      if transaction.status.failed?
        withdrawal.fail!
      elsif transaction.status.success? && latest_block_number - withdrawal.block_number >= blockchain.min_confirmations
        withdrawal.success!
      end
    rescue => err
      Bugsnag.notify err do |b|
        b.meta_data = { tx: transaction }
      end
      logger.error "#{err.message} for #{transaction}"
    end
  end

  def fetch_transaction(tx)
    return tx unless tx.status.pending?
    @fetched_transaction ||= gateway.fetch_transaction tx.txid, tx.txout
  end

  def logger
    Rails.logger
  end
end
