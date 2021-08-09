class WalletService
  attr_reader :wallet, :adapter

  ALLOWED_INCENTIVE_GATEWAY='dummy'

  def initialize(wallet)
    @wallet = wallet
    @adapter = wallet.adapter
  end

  # TODO: We don't need deposit_spread anymore.
  def deposit_collection_fees!(deposit, deposit_spread)
    configs = {
      wallet:   @wallet.to_wallet_api_settings,
      currency: deposit.currency.to_blockchain_api_settings
    }

    if deposit.currency.parent_id?
      configs.merge!(parent_currency: deposit.currency.parent.to_blockchain_api_settings)
    end

    @adapter.configure(configs)
    deposit_transaction = Peatio::Transaction.new(hash:         deposit.txid,
                                                  txout:        deposit.txout,
                                                  to_address:   deposit.address,
                                                  block_number: deposit.block_number,
                                                  amount:       deposit.amount)

    transactions = @adapter.prepare_deposit_collection!(deposit_transaction,
                                                        # In #spread_deposit valid transactions saved with pending state
                                                        deposit_spread.select { |t| t.status.pending? },
                                                        deposit.currency.to_blockchain_api_settings)

    if transactions.present?
      updated_spread = deposit.spread.map do |s|
        deposit_options = s.fetch(:options, {}).symbolize_keys
        transaction_options = transactions.first.options.presence || {}
        general_options = deposit_options.merge(transaction_options)

        s.merge(options: general_options)
      end

      deposit.update(spread: updated_spread)

      transactions.each { |t| save_transaction(t.as_json.merge(from_address: @wallet.address), deposit) }
    end
    transactions
  end

  def refund!(refund)
    pa = PaymentAddress.find_by(
      blockchain: refund.deposit.blockchain,
      member: refund.deposit.member,
      address: refund.deposit.address)
    # NOTE: Deposit wallet configuration is tricky because wallet URI
    #       is saved on Wallet model but wallet address and secret
    #       are saved in PaymentAddress.
    @adapter.configure(
      wallet: @wallet.to_wallet_api_settings
                     .merge(pa.details.symbolize_keys)
                     .merge(address: pa.address)
                     .tap { |s| s.merge!(secret: pa.secret) if pa.secret.present? }
                     .compact
    )

    refund_transaction = Peatio::Transaction.new(to_address: refund.address,
                                                 amount: refund.deposit.amount,
                                                 currency_id: refund.deposit.currency_id)
    @adapter.create_transaction!(refund_transaction, subtract_fee: true)
  end

  def register_webhooks!(url)
    @adapter.register_webhooks!(url)
  end

  def fetch_transfer!(id)
    @adapter.fetch_transfer!(id)
  end

  def trigger_webhook_event(event)
    # If there are erc20 currencies we should configure parent currency here
    currency = @wallet.currencies.find { |e| e.parent_id == nil }
    @adapter.configure(wallet:   @wallet.to_wallet_api_settings,
                       currency: currency.to_blockchain_api_settings)
    @adapter.trigger_webhook_event(event)
  end

  def skip_deposit_collection?
    @adapter.features[:skip_deposit_collection]
  end
  # Record blockchain transactions in DB
  def save_transaction(transaction, reference)
    transaction['txid'] = transaction.delete('hash')
    Transaction.create!(transaction.merge(reference: reference))
  end
end
