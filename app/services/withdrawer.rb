# frozen_string_literal: true

class Withdrawer
  class Error < StandardError
    def initialize(message, options = {})
      @options = options
      @message = message
    end

    def as_json
      @options.merge message: @message
    end

    def to_s
      @message
    end
  end

  Fail = Class.new Error
  Busy = Class.new Error
  NoHotWallet = Class.new Error
  WalletLowBalance = Class.new Error

  attr_reader :logger

  def initialize(logger = nil)
    @logger = logger || TaggedLogger.new(Rails.logger, worker: __FILE__)
  end

  def call(withdraw, nonce: nil, gas_factor: nil)
    return if %w[heco-mainnet eth-ropsten].include?(withdraw.blockchain.key)

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

      transaction = push_transaction_to_gateway! withdraw, nonce: nonce, gas_factor: gas_factor

      logger.warn id: withdraw.id,
                  txid: transaction.id,
                  transcation: transaction.as_json,
                  message: 'Blockchain transcation created'

      withdraw.update!(
        metadata: (withdraw.metadata.presence || {}).merge(transaction.options || {}), # Saves links and etc
        txid: transaction.hash || raise("transaction does not have hash #{transaction} for withdraw #{withdraw.id}"),
        tx_dump: transaction.as_json
      )

      logger.warn id: withdraw.id,
                  txid: transaction.hash,
                  message: 'The currency API accepted withdraw and assigned transaction ID.'
      withdraw.dispatch!

    rescue Busy, Fail => e
      # TODO: repeat withdraw for Busy
      withdraw.fail!
      logger.warn e.as_json.merge(id: withdraw.id)
    rescue WalletLowBalance => e
      Peatio::SlackNotifier.notifications.ping(e.message)
      logger.warn e.as_json.merge(withdraw_id: withdraw.id)
      report_exception e, true, withdraw_id: withdraw.id
      withdraw.err! e
    rescue Ethereum::Client::InsufficientFunds
      withdraw.fail!
      logger.warn(message: 'Insufficient funds', withdraw_id: withdraw.id)
    end
  rescue StandardError => e
    logger.warn id: withdraw.id, message: 'Setting withdraw state to errored.'
    report_exception e, true, withdraw_id: withdraw.id
    withdraw.err! e

    raise e if is_db_connection_error?(e)
  end

  private

  def push_transaction_to_gateway!(withdraw, nonce: nil, gas_factor: nil)
    withdraw_wallet =
      withdraw
      .blockchain
      .withdraw_wallet_for_currency(withdraw.currency) ||
      raise(NoHotWallet, 'No hot withdraw wallet for withdraw', withdraw_id: withdraw.id)

    # TODO: updates wallet balance and validate that withdraw can be executed before creating transaction
    BalancesUpdater.new(blockchain: withdraw_wallet.blockchain, address: withdraw_wallet.address).perform

    raise WalletLowBalance.new("Low balance on hot wallet: #{withdraw_wallet.name}(#{withdraw_wallet.id}) for withdraw", wallet_id: withdraw_wallet.id) unless withdraw_wallet.can_withdraw_for?(withdraw)

    contract_address = BlockchainCurrency.find_by(blockchain: withdraw_wallet.blockchain, currency: withdraw.currency)&.contract_address
    withdraw_wallet.blockchain.gateway
                   .create_transaction!(
                     from_address: withdraw_wallet.address,
                     to_address: withdraw.to_address,
                     amount: withdraw.money_amount,
                     contract_address: contract_address,
                     secret: withdraw_wallet.secret,
                     blockchain_address: (withdraw_wallet.parent ? withdraw_wallet.parent.blockchain_address : withdraw_wallet.blockchain_address),
                     nonce: nonce,
                     gas_factor: gas_factor,
                     meta: { withdraw_tid: withdraw.tid }
                   ) || raise("No transaction returned for withdraw (#{withdraw.id})")
  end
end
