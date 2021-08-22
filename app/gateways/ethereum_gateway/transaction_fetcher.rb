class EthereumGateway
  class TransactionFetcher < AbstractCommand
    def call(txid, txout = nil)
      txn_json = client.json_rpc(:eth_getTransactionByHash, [txid])

      return nil if txn_json.nil?
      # base currency transaction
      if txn_json.fetch('input').hex <= 0
        build_success_eth_transaction(txn_json, txout)
      else # erc20 transcation
        txn_receipt = fetch_receipt txid
        return if txn_receipt.nil?
        return build_invalid_erc20_transaction(txn_receipt) if txn_json.nil?
        transcations = build_erc20_transactions(txn_receipt, follow_txids: [txid], follow_txouts: [txout])
        raise 'wtf' if transcations.many?
        transcations.first
      end
    rescue Ethereum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end
  end
end
