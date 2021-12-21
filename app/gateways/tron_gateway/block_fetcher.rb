# frozen_string_literal: true

class TronGateway
  module BlockFetcher
    def enable_block_fetching?
      true
    end

    def fetch_block_transactions(block_number)
      txs = client.json_rpc(path: 'wallet/getblockbynum', params: { num: block_number })
      txn_receipts_map = client.json_rpc(path: 'wallet/gettransactioninfobyblocknum', params: { num: block_number })
                               .index_by { |r| r['id'] }

      result = txs.fetch('transactions', []).each_with_object([]) do |tx, txs_array|
        txn_receipt = txn_receipts_map[tx['txID']]

        tx_contract = tx.dig('raw_data', 'contract')[0]
        tx_type = tx_contract.fetch('type', nil)

        case tx_type
        when 'TransferContract'
          next if invalid_transaction?(tx)
        when 'TriggerSmartContract'
          next if tx.nil? || invalid_trc20_transaction?(txn_receipt)
        else
          next
        end

        txs_array.append(build_transaction(tx, txn_receipt))
      end

      result.flatten.compact.map { |tx| monefy_transaction(tx) }
    rescue Tron::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end
  end
end
