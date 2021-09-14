class EthereumGateway
  class DepositCollector < AbstractCommand
    def call(deposit)
      pa = deposit.payment_address
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

      deposit.with_lock do
        deposit.spread.map do |spread|
          spread_transaction = Peatio::Transaction.new spread

          # In #spread_deposit valid transactions saved with pending state
          if spread_transaction.status.pending?
            transaction = client.create_transaction!(transaction, subtract_fee: true)

            # TODO: update spread_transaction state to failed
            return if transaction.nil?

            # TODO: update spread_transaction state to created
            Transaction.create!(
              transaction.merge(reference: deposit, txid: transaction.delete('hash'))
            )
          end
        end
      end
    end
  end
end
