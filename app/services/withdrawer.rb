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

  Error = Class.new StandardError
  Fail = Class.new Error
  Busy = Class.new Error

  attr_reader :wallet, :logger

  def initialize(wallet, logger = nil)
    @wallet = wallet || raise("No wallet")
    @logger = logger || TaggedLogger.new(Rails.logger, worker: __FILE__)
  end

  def call(withdraw)
    withdraw.lock!.transfer!

    withdraw.with_lock do
      raise Busy, 'The withdraw is being processed by another worker or has already been processed.' unless withdraw.transfering?
      raise Fail, 'The destination address doesn\'t exist.' if withdraw.rid.blank?

      logger.warn id: withdraw.id,
        amount: withdraw.amount.to_s('F'),
        fee: withdraw.fee.to_s('F'),
        currency: withdraw.currency.code.upcase,
        rid: withdraw.rid,
        message: 'Sending withdraw.'

      transaction = create_transaction! withdraw

      # TODO create withdrawal transaction from blockchain service
      Transaction.create!(
        from_address: transaction.from_address,
        to_address: transaction.to_address,
        reference: withdraw,
        currency: withdraw.currency,
        amount: withdraw.currency.to_money(transaction.amount),
        options: transaction.options,
      )

      withdraw.update!(
        metadata: (withdraw.metadata.presence || {}).merge(transaction.options || {}), # Saves links and etc
        txid: transaction.hash || raise("transaction does not have hash #{transaction} for withdraw #{withdraw.id}")
      )

      logger.warn id: withdraw.id,
        tid: transaction.hash,
        message: 'The currency API accepted withdraw and assigned transaction ID.'
      withdraw.dispatch!

    rescue Busy => e
      # TODO repeat withdraw
      withdraw.fail!
      logger.warn e.as_json.merge( id: withdraw.id )
    rescue Fail => e
      withdraw.fail!
      logger.warn e.as_json.merge( id: withdraw.id )
    rescue StandardError => e
      logger.warn id: withdraw.id, message: 'Failed to process withdraw. See exception details below.'
      report_exception(e)
      withdraw.err! e

      raise e if is_db_connection_error?(e)

      logger.warn id: withdraw.id,
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

    raise "transaction.from_address (#{transaction.from_address})<> wallet.address (#{wallet.address})" unless transaction.from_address == wallet.address

    transaction
  end

  private

end
