class EthereumGateway
  class BlockFetcher < AbstractCommand
    ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

    def call(block_number, contract_addresses=[], allowed_contracts=[])
      block_json = client.json_rpc(:eth_getBlockByNumber, ["0x#{block_number.to_s(16)}", true])

      if block_json.blank? || block_json['transactions'].blank?
        return Peatio::Block.new(block_number, [])
      end
      block_json.fetch('transactions').each_with_object([]) do |tx, block_arr|
        if tx.fetch('input').hex <= 0
          next if invalid_eth_transaction?(tx)
        else
          process_tx = false

          # 1. Check if the smart contract destination is in whitelist
          #    The common case is a withdraw from a known smart contract of a major exchange
          if allowed_contracts.include? normalize_address(tx.fetch('to'))
            process_tx = true
          else
            # 2. Check if the transaction is one of our currencies smart contract
            contract_addresses.each do |c|
              next if c.contract_address != normalize_address(tx.fetch('to'))

              # Check if the tx is from one of our wallets (to confirm withdrawals)
              if Wallet.withdraw.where(address: normalize_address(tx.fetch('from'))).present?
                process_tx = true
                break
              end

              input = tx.fetch('input')
              # The usual case is a function call transfer(address,uint256) with footprint 'a9059cbb'

              # Check if one of the first params of the function call is one of our deposit addresses
              args = ["0x#{input[34...74]}", "0x#{input[75...115]}"]
              args.delete(ZERO_ADDRESS)
              if PaymentAddress.where(address: args).present?
                process_tx = true
                break
              end
            end
          end

          next unless process_tx

          tx_id = normalize_txid(tx.fetch('hash'))
          Rails.logger.debug "Fetching tx receipt #{tx_id}"
          tx = client.json_rpc(:eth_getTransactionReceipt, [tx_id])
          next if tx.nil? || tx.fetch('to').blank?
        end

        txs = build_transactions(tx).map do |ntx|
          Peatio::Transaction.new(ntx)
        end

        block_arr.append(*txs)
      end.yield_self { |block_arr| Peatio::Block.new(block_number, block_arr) }
    rescue Ethereum::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    private

    def invalid_eth_transaction?(block_txn)
      block_txn.fetch('to').blank? \
        || block_txn.fetch('value').hex.to_d <= 0 && block_txn.fetch('input').hex <= 0
    end
  end
end
