class EthereumGateway
  class BlockFetcher < AbstractCommand
    TOKEN_EVENT_IDENTIFIER = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'

    def call(block_number, contract_addresses: [], follow_addresses: [], follow_txids: [])
      # logger.info("Fetch block #{block_number} with contract_addresses: #{contract_addresses} and follow_addresses #{follow_addresses}")
      logger.debug("Fetch block #{block_number}")
      @contract_addresses = contract_addresses
      @follow_addresses = follow_addresses
      @follow_txids = follow_txids
      block_json = client.json_rpc(:eth_getBlockByNumber, ["0x#{block_number.to_s(16)}", true])

      return [] if block_json.blank? || block_json['transactions'].blank?

      transactions = []
      block_json.fetch('transactions').each do |tx|
        next if invalid_eth_transaction?(tx)

        if tx.fetch('input').hex <= 0
          from_address = normalize_address(tx['from'])
          to_address = normalize_address(tx['to'])
          transactions << build_eth_transaction(tx) if follow_addresses.include?(from_address) ||
            follow_addresses.include?(to_address) ||
            follow_txids.include?(normalize_txid(tx.fetch('hash')))
        else
          contract_address = normalize_address tx.fetch('to')
          from_address = normalize_address tx.fetch('from')
          to_address = get_address_from_input tx.fetch('input')

          # 1. Check if the smart contract destination is in whitelist
          #    The common case is a withdraw from a known smart contract of a major exchange (TODO)
          # 2. Check if the transaction is one of our currencies smart contract
          # 3. Check if the tx is from one of our wallets (to confirm withdrawals)
          next unless contract_addresses.include?(contract_address) || follow_addresses.include?(from_address) || follow_addresses.include?(to_address)

          transactions += build_erc20_transactions(fetch_erc20_transaction tx.fetch('hash'))
        end
      end
      logger.info("Fetching block #{block_number} finished with #{transactions.count} transactions catched")
      transactions.compact
    rescue Ethereum::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    private

    attr_reader :follow_addresses, :contract_addresses, :follow_txids

    # The usual case is a function call transfer(address,uint256) with footprint 'a9059cbb'
    def get_address_from_input(input)
      # Check if one of the first params of the function call is one of our deposit addresses
      ["0x#{input[34...74]}", "0x#{input[75...115]}"].tap do |to_address|
        to_address.delete(ZERO_ADDRESS)
      end
    end

    def process_transaction(tx)
      build_eth_transaction(tx_hash)
    end

    def fetch_erc20_transaction(tx_id)
      # logger.debug "Fetching tx receipt #{tx_id}"
      tx = client.json_rpc(:eth_getTransactionReceipt, [tx_id])
      return if tx.nil? || tx.fetch('to').blank?
      tx
    end

    def invalid_eth_transaction?(block_txn)
      block_txn.fetch('to').blank? \
        || block_txn.fetch('value').hex.to_d <= 0 && block_txn.fetch('input').hex <= 0
    end

    #def build_transaction(tx_hash)
      #if tx_hash.has_key?('logs')
        #build_erc20_transactions(tx_hash)
      #else
        #build_eth_transaction(tx_hash)
      #end
    #end

    def build_eth_transaction(block_txn)
        {
          hash:           normalize_txid(block_txn.fetch('hash')),
          amount:         block_txn.fetch('value').hex,
          from_addresses: [normalize_address(block_txn['from'])],
          to_address:     normalize_address(block_txn['to']),
          txout:          block_txn.fetch('transactionIndex').to_i(16),
          block_number:   block_txn.fetch('blockNumber').to_i(16),
          status:         transaction_status(block_txn),
          options: {
            gas:            block_txn.fetch('gas').to_i(16),
            gas_price:      block_txn.fetch('gasPrice').to_i(16),
          },
          fee:            block_txn.fetch('gas').to_i(16) * block_txn.fetch('gasPrice').to_i(16),
          contract_address: nil
        }
    end

    def build_erc20_transactions(txn_receipt)
      # Build invalid transaction for failed withdrawals
      return [build_invalid_erc20_transaction(txn_receipt)] if transaction_status(txn_receipt) == 'failed' && txn_receipt.fetch('logs').blank?

      txn_receipt.fetch('logs').each_with_object([]) do |log, formatted_txs|
        next if log['blockHash'].blank? && log['blockNumber'].blank?
        next if log.fetch('topics').blank? || log.fetch('topics')[0] != TOKEN_EVENT_IDENTIFIER

        contract_address = log.fetch('address')
        next unless contract_addresses.include? contract_address

        to_address = normalize_address('0x' + log.fetch('topics').last[-40..-1])
        from_address = normalize_address(txn_receipt['from'])

        txid = normalize_txid(txn_receipt.fetch('transactionHash'))
        next unless follow_addresses.include?(to_address) || follow_addresses.include?(from_address) || follow_txids.include?(txid)
        formatted_txs << {
          hash:            txid,
          amount:          log.fetch('data').hex,
          from_addresses:  [from_address],
          to_address:      to_address,
          txout:           log['logIndex'].to_i(16),
          block_number:    txn_receipt.fetch('blockNumber').to_i(16),
          contract_address: log.fetch('address'),
          status:          transaction_status(txn_receipt),
          options: { gas_price: txn_receipt.fetch('effectiveGasPrice').to_i(16) },
          fee:  txn_receipt.fetch('effectiveGasPrice').to_i(16) * txn_receipt.fetch('gasUsed').to_i(16)
        }
      end
    end

    def build_invalid_erc20_transaction(txn_receipt)
      return unless contract_addresses.include? txn_receipt.fetch('to')

      {
        hash:         normalize_txid(txn_receipt.fetch('transactionHash')),
        block_number: txn_receipt.fetch('blockNumber').to_i(16),
        contract_address: txn_receipt.fetch('to'),
        amount: 0,
        status:       transaction_status(txn_receipt),
      }
    end
  end
end
