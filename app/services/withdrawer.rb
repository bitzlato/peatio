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

  Invalid = Class.new StandardError

  attr_reader :wallet

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
        message: 'Sending withdraw.'

      transaction = create_transaction! withdraw

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
    transaction = withdraw.blockchain.gateway.
      create_transaction!(
        from_address: wallet.address,
        to_address: withdraw.to_address,
        amount: withdraw.money_amount,
        contract_address: withdraw.money_amount.currency.contract_address,
        secret: wallet.secret,
    ) || raise("No transaction returned for withdraw (#{withdraw.id})")

    # TODO create withdrawal transaction from blockchain service
    Transaction
      .create!(
        transaction.as_json.merge(from_address: wallet.address, reference: withdraw, txid: transaction.delete('hash'))
    )

    withdraw.update!(
      metadata: withdraw.metadata.merge(transaction.options), # Saves links and etc
      txid: transaction.hash || raise("transaction does not have hash #{transaction} for withdraw #{withdraw.id}")
    )
    raise "transaction for withdraw #{withdraw.id} is not succeed #{transaction}" unless transaction.status == 'succeed'

    logger.warn id: withdraw.id,
      tid: transaction.hash,
      message: 'The currency API accepted withdraw and assigned transaction ID.'
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

    # А есть ли смысл проверять баланс, если нода всеравно вернет ошибку?
    # TODO ловить и обрабатывать ошибки от ноды
    #balance = wallet.current_balance(withdraw.currency)
    #if balance == Wallet::NOT_AVAILABLE || balance < withdraw.amount
      #withdraw.skip!
      #raise(
        #Invalid,
        #'The withdraw skipped because wallet balance is not sufficient or amount greater than wallet max_balance.',
        #balance: balance.to_s,
        #amount: withdraw.amount.to_s
      #)
    #end
  end
end
