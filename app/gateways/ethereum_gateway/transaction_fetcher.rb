class EthereumGateway
  class TransactionFetcher < AbstractCommand
    def call
      def fetch_transaction(txid, txout = nil)
        txn_receipt = client.json_rpc(:eth_getTransactionReceipt, [txid])
        if currency[:id] == @eth[:id]
          txn_json = client.json_rpc(:eth_getTransactionByHash, [txid])
          attributes = {
            amount: convert_from_base_unit(txn_json.fetch('value').hex, currency),
            to_address: normalize_address(txn_json['to']),
            txout: txn_json.fetch('transactionIndex').to_i(16),
            status: transaction_status(txn_receipt)
          }
        else
          if txout.present?
            txn_json = txn_receipt.fetch('logs').find { |log| log['logIndex'].to_i(16) == txout }
          else
            txn_json = txn_receipt.fetch('logs').first
          end
          attributes = {
            amount: convert_from_base_unit(txn_json.fetch('data').hex, currency),
            to_address: normalize_address('0x' + txn_json.fetch('topics').last[-40..-1]),
            status: transaction_status(txn_receipt)
          }
        end

        Peatio::Transaction.new attributes.reverse_merge(txid: txid, txout: txout)
      rescue Ethereum::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end
    end
  end
end
