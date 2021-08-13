class EthereumGateway
  class TransactionFetcher < AbstractCommand
    def call(txid, txout = nil)
      txn_json = client.json_rpc(:eth_getTransactionByHash, [txid])
      txn_receipt = client.json_rpc(:eth_getTransactionReceipt, [txid])

      # base currency transaction
      if txn_json.fetch('input').hex <= 0
        attributes = {
          amount: txn_json.fetch('value').hex,
          from_addresses: [normalize_address(txn_json['from'])],
          to_address: normalize_address(txn_json['to']),
          txout: txn_json.fetch('transactionIndex').to_i(16),
          status: transaction_status(txn_receipt),
          contract_address: nil,
          block_number: txn_json.fetch('blockNumber').hex,
        }
      else # erc20 transcation
        txn_json = if txout.present?
          txn_receipt.fetch('logs').find { |log| log['logIndex'].to_i(16) == txout }
        else
          txn_receipt.fetch('logs').first
        end
        attributes = {
          amount: txn_json.fetch('data').hex,
          to_address: normalize_address('0x' + txn_json.fetch('topics').last[-40..-1]),
          from_address: normalize_address(txn_receipt['from']),
          status: transaction_status(txn_receipt),
          contract_address: normalize_address(txn_json.fetch('to')),
          txout: txout,
          block_number: txn_json.fetch('blockNumber').hex,
        }
      end

      attributes.reverse_merge(txid: txid, txout: txout)
    rescue Ethereum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    private

    def fetch_erc20_transaction(tx_id)
      Rails.logger.debug "Fetching tx receipt #{tx_id}"
      tx = client.json_rpc(:eth_getTransactionReceipt, [tx_id])
      return if tx.nil? || tx.fetch('to').blank?
      tx
    end
  end
end
