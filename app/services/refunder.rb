class Refunder
  def refund!(refund)
    pa = PaymentAddress.find_by(
      blockchain: refund.deposit.blockchain,
      member: refund.deposit.member,
      address: refund.deposit.address
    )
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
end
