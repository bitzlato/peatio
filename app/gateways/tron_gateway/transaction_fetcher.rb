# frozen_string_literal: true

class TronGateway
  module TransactionFetcher
    def fetch_transaction(txid, _txout = nil)
      tx = client.json_rpc(path: 'wallet/gettransactionbyid', params: { value: txid })
      return if tx.nil?

      txn_receipt = client.json_rpc(path: 'wallet/gettransactioninfobyid', params: { value: txid })

      monefy_transaction(
        Array.wrap(build_transaction(tx, txn_receipt))&.first
      )
    end
  end
end
