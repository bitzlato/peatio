# frozen_string_literal: true

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
    blockchain.transactions.pluck(:txid, :txout).each do |txid, txout|
      unless blockchain.valid_txid? txid
        logger.info("Transaction address #{txid} is invalid")
        next
      end
      refetch_and_update_transaction!(txid, txout)
    rescue StandardError => e
      report_exception e, true, transaction_id: t.id
    end
  end

  def delete_unknown_transactions!
    txids = blockchain.deposits.pluck(:txid) + blockchain.withdraws.pluck(:txid)
    addresses = blockchain.follow_addresses
    destroyed = 0
    blockchain.transactions.where(reference_id: nil).find_each do |t|
      next if txids.include?(t.txid) || addresses.include?(t.from_address) || addresses.include?(t.to_address)

      destroyed += 1
      t.destroy!
    end
    destroyed
  end

  def refetch_and_update_transaction!(txid, txout = nil)
    monyfied_blockchain_transaction = gateway.fetch_transaction txid, txout
    if monyfied_blockchain_transaction.nil?
      t = blockchain.transactions.find_by(txid: txid, txout: txout)
      report_exception("Unknown transaction #{txid}/#{txout} for #{blockchain.key}", true) if t.present?
      nil
    else
      # TODO: lookup for reference if there are no transaction
      Transaction.upsert_transaction! monyfied_blockchain_transaction
    end
  end

  def process_block(block_number)
    dispatch_deposits! block_number

    Blockchain.transaction do
      bn = blockchain
           .block_numbers
           .upsert!(number: block_number, error_message: nil, status: :processing)
           .lock!

      transactions = gateway.fetch_block_transactions(block_number)

      withdraw_scope = blockchain.withdraws.where.not(txid: nil).where(block_number: [nil, block_number])
      withdraw_txids = if Rails.env.production?
                         withdraw_scope.confirming.pluck(:txid)
                       else
                         # Check it all, we want debug in development
                         withdraw_scope.pluck(:txid)
                       end

      processed_count = transactions.each do |tx|
        if tx.topic == :approval
          BlockchainApproval.upsert_transaction!(tx)
        else
          @withdrawal = @deposit = @fetched_transaction = nil
          update_or_create_withdraw(tx) if tx.hash.in?(withdraw_txids)
          update_or_create_deposit(tx) if tx.to_address.in?(blockchain.deposit_addresses) && (!tx.from_address.in?(blockchain.wallets_addresses) || tx.hash.in?(withdraw_txids)) # Skip gas refueling
          # TODO: fetch_transaction if status is pending
          tx = fetch_transaction(tx)
          Transaction.upsert_transaction! tx, reference: (deposit || withdrawal)

          AMQP::Queue.enqueue('balances_updating', { blockchain_id: blockchain.id, address: tx.from_address }) if blockchain.follow_addresses.include?(tx.from_address)
          AMQP::Queue.enqueue('balances_updating', { blockchain_id: blockchain.id, address: tx.to_address }) if blockchain.follow_addresses.include?(tx.to_address)
        end
      end.count

      bn.update!(
        transactions_processed_count: processed_count, error_message: nil, status: :success
      )

      processed_count
    rescue StandardError => e
      bn.update!(
        transactions_processed_count: 0, error_message: e.message, status: :error
      )
      report_exception e, true, blockchain_id: blockchain.id, block_number: block_number
      raise e
      0
    end
  end

  # Resets current cached state.
  def reset!
    @latest_block_number = nil
  end

  def update_height(block_number)
    current_height = blockchain.height
    new_height = blockchain.reload.height
    raise Error, "#{blockchain.name} height was reset. Current height: #{current_height}, New height: #{new_height}" if current_height != new_height

    # NOTE: We use update_column to not change updated_at timestamp
    # because we use it for detecting blockchain configuration changes see Workers::Daemon::Blockchain#run.
    blockchain.update_columns height: block_number, height_updated_at: Time.zone.now, client_version: gateway.client_version if latest_block_number - block_number >= blockchain.min_confirmations
  end

  private

  attr_reader :withdrawal, :deposit, :fetched_transaction

  def dispatch_deposits!(_block_number)
    blockchain
      .deposits
      .accepted
      .where('block_number <= ?', latest_block_number - blockchain.min_confirmations)
      .lock
      .find_each do |deposit|
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
      blockchain_id: blockchain.id,
      currency_id: transaction.currency_id,
      txid: transaction.hash,
      txout: transaction.txout # what for? it is usable for blockchain only?
    ) do |d|
      d.address = transaction.to_address
      d.money_amount = transaction.amount
      d.member = address.member
      d.from_addresses = transaction.from_addresses.presence || raise('No transaction from_addresses')
      d.block_number = transaction.block_number || raise("Transaction #{transaction} has no block_number")
    end
    deposit.with_lock do
      if deposit.block_number.nil?
        logger.debug("Set block_number #{transaction.block_number} for deposit #{deposit.id}")
        deposit.update! block_number: transaction.block_number
      end
      raise "Amounts different #{deposit.id}" unless transaction.amount == deposit.money_amount

      logger.info("Found or created suitable deposit #{deposit.id} for txid #{transaction.id}, amount #{transaction.amount}")
      if deposit.submitted?
        member = deposit.member
        skipped_deposits = member.deposits.skipped.where(currency: transaction.amount.currency.currency_record, blockchain: blockchain).lock
        total_skipped_amount = skipped_deposits.sum(&:money_amount)
        min_deposit_amount_money = BlockchainCurrency.find(transaction.amount.currency.blockchain_currency_record.id).min_deposit_amount_money

        if (total_skipped_amount + transaction.amount) < min_deposit_amount_money
          skip_message = "Skipped deposit with txid: #{transaction.hash}"\
                         " to #{transaction.to_address} in block number #{transaction.block_number}"\
                         " because of low amount (#{transaction.amount.format} < #{min_deposit_amount_money.format})"
          logger.warn skip_message
          deposit.skip!
          deposit.add_error skip_message
        else
          logger.info("Accepting deposit #{deposit.id}")
          deposit.accept!

          if skipped_deposits.any?
            logger.info("Accepting skipped deposits #{skipped_deposits.map(&:id).join(', ')}")
            skipped_deposits.each(&:accept!)
          end
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
    rescue StandardError => e
      logger.error "#{e.message} for #{transaction}"
      report_exception e, true, tx: transaction
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
