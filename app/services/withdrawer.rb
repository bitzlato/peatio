class Withdrawer
  class Error < StandardError
    def initialize(message, options={})
      @options = options
      @message = message
    end
    def as_json
      options.merge message: message
    end
    def to_s
      message
    end
  end

  Invlalid = Class.new StandardError

  def initialize(wallet, logger = nil)
    @wallet = wallet
    @logger = logger || TaggedLogger.new(Rails.logger, worker: __FILE__)
  end

  def call(withdraw)
    withdraw.lock!.transfer!

    withdraw.with_lock do
      validate! withdraw

      @logger.warn id: withdraw.id,
        amount: withdraw.amount.to_s('F'),
        fee: withdraw.fee.to_s('F'),
        currency: withdraw.currency.code.upcase,
        rid: withdraw.rid,
        message: 'Sending witdraw.'

      transaction = create_transaction! witdraw

      @logger.warn id: withdraw.id, message: 'Withdrawal has processed', txid: transaction.id

      withdraw.dispatch!

    rescue Invalid => e
      @logger.warn e.as_json.merge( id: withdraw.id )
    rescue StandardError => e
      @logger.warn id: withdraw.id, message: 'Failed to process withdraw. See exception details below.'
      report_exception(e)
      withdraw.err! e

      raise e if is_db_connection_error?(e)

      @logger.warn id: withdraw.id,
                   message: 'Setting withdraw state to errored.'
    end
  end

  private

  def create_transaction!(withdraw)
    source_transaction = Peatio::Transaction.new(to_address: withdraw.rid,
                                                 amount:     withdraw.amount,
                                                 currency_id: withdraw.currency_id,
                                                 options: { tid: withdraw.tid, withdrawal_id: withdraw.id })

    transaction = client.create_transaction!(source_transaction) ||
      raise("No transaction returned for withdraw (#{withdraw.id})")

    # is from_address dfinedx?
    Transaction
      .create!(
        transaction.as_json.merge(from_address: wallet.address, reference: withdraw, txid: transaction.delete('hash'))
    )

    raise "transaction for withdraw #{withdraw.id} is not succeed #{transaction}" unless transaction.status == 'succeed'

    logger.warn id: withdraw.id,
      tid: transaction.hash,
      message: 'The currency API accepted withdraw and assigned transaction ID.'

    withdraw.assign_attributes(
      metadata: withdraw.metadata.merge(transaction.options), # Saves links and etc
      txid: transaction.hash || raise("transaction does not have hash #{transaction} for withdraw #{withdraw.id}")
    )
    withdraw.success
    withdraw.save!
  end

  private

  def validate!(withdraw)
    unless withdraw.transfering?
      raise Invalid, 'The withdraw is being processed by another worker or has already been processed.'
    end

    if withdraw.rid.blank?
      withdraw.fail!
      raise Invalid, 'The destination address doesn\'t exist.'
    end

    unless wallet
      withdraw.skip!
      raise Invalid, "Can\'t find active hot wallet for currency", currency: withdraw.currency.id
    end

    balance = wallet.current_balance(withdraw.currency)
    if balance == Wallet::NOT_AVAILABLE || balance < withdraw.amount
      withdraw.skip!
      raise(
        Invalid,
        'The withdraw skipped because wallet balance is not sufficient or amount greater than wallet max_balance.',
        balance: balance.to_s,
        amount: withdraw.amount.to_s
      )
    end
  end
end
