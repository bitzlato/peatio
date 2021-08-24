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

  def update_transactions!
    blockchain.transactions.each do |t|
      unless blockchain.valid_address? t.txid
        logger.debug("Transaction address #{t.txid} is invalid")
        next
      end
      is_followed  = blockchain.follow_addresses.include?(t.to_address) ||
        blockchain.follow_addresses.include?(t.from_address) ||
        blockchain.follow_txids.include?(t.txid)
      update_transaction!(t.txid, t.txout, is_followed)
    rescue => err
      report_exception err, true, transaction_id: t.id
    end
  end

  def delete_unknown_transactions!
    txids = blockchain.deposits.pluck(:txid) + blockchain.withdraws.pluck(:txid)
    addresses = blockchain.follow_addresses
    destroyed = 0
    blockchain.transactions.where(reference_id: nil).find_each do |t|
      next if txids.include?(t.txid) || addresses.include?(t.from_address) || addresses.include?(t.to_address)
      destroyed +=1
      t.destroy!
    end
    destroyed
  end

  def update_transaction!(txid, txout = nil, is_followed = false)
    blockchain_transaction = gateway.fetch_transaction txid, txout
    t = blockchain.transactions.find_by(txid: txid, txout: txout)
    if blockchain_transaction.nil?
      t.update status: 'pending' if t.present?
    else
      # TODO lookup for reference if there are no transaction
      Transaction.upsert_transaction! blockchain_transaction, is_followed: is_followed
    end
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
        update_or_create_deposit tx unless tx.from_address.include?(blockchain.wallets_addresses) # Skip gas refueling
      elsif tx.hash.in?(withdraw_txids)
        update_or_create_withdraw tx
      end
      # TODO fetch_transaction if status is pending
      tx = fetch_transaction(tx)
      Transaction.upsert_transaction! tx, reference: (deposit || withdrawal)
    end.count
  rescue StandardError => err
    report_exception err, true, blockchain_id: blockchain.id, block_number: block_number
    raise err
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

    # Fetch transaction from a blockchain that has `pending` status.
    transaction = fetch_transaction(transaction)
    unless transaction.status.success?
      logger.info do
        "Skipped deposit with txid: #{transaction.hash} because of status #{transaction.status}"
      end
      return
    end


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
        if transaction.amount < Currency.find(transaction.amount.currency.id).min_deposit_amount_money
          skip_message = "Skipped deposit with txid: #{transaction.hash}"\
              " to #{transaction.to_address} in block number #{transaction.block_number}"\
              " because of low amount (#{transaction.amount.format} < #{Currency.find(transaction.amount.currency.id).min_deposit_amount_money.format})"
          logger.warn skip_message
          deposit.skip!
          deposit.add_error skip_message
        else
          logger.info("Accepting deposit #{deposit.id}")
          deposit.accept!
        end
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
      logger.error "#{err.message} for #{transaction}"
      report_exception err, true, tx: transaction
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
