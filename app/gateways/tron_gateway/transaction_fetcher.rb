# frozen_string_literal: true

class TronGateway
  module TransactionFetcher
    def fetch_transaction(txid, _txout = nil)
      tx = client.json_rpc(path: 'wallet/gettransactionbyid', params: { value: reformat_txid(txid) })
      return if tx.nil?

      txn_receipt = client.json_rpc(path: 'wallet/gettransactioninfobyid', params: { value: reformat_txid(txid) })

      monefy_transaction(
        build_transaction(tx, txn_receipt)&.first
      )
    end
  end
end
