class EthereumGateway
  class BlockProcessor < AbstractCommand
    TOKEN_EVENT_IDENTIFIER = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
    SUCCESS = '0x1'
    FAILED = '0x0'

    def call(block_number,
             withdraw_checker: ->(_a) { true },
             deposit_checker: ->(_a) { true },
             system_addresses: ->(_a) { true },
             amount_converter: ->(amount, _contract_address) { amount },
             contract_addresses: [],
             allowed_contracts: [])
      @contract_addresses = contract_addresses
      @amount_converter = amount_converter
      block_json = client.json_rpc(:eth_getBlockByNumber, ["0x#{block_number.to_s(16)}", true])

      return if block_json.blank? || block_json['transactions'].blank?

      @transactions = []

      block_json.fetch('transactions').each do |tx|
        next if invalid_eth_transaction?(tx)

        if tx.fetch('input').hex <= 0
          @transactions << build_eth_transaction(tx)
          next
        end

        contract_address = normalize_address tx.fetch('to')
        address_from = normalize_address tx.fetch('from')
        address_to = get_address_from_input tx.fetch('input')

        # 1. Check if the smart contract destination is in whitelist
        #    The common case is a withdraw from a known smart contract of a major exchange (TODO)
        # 2. Check if the transaction is one of our currencies smart contract
        # 3. Check if the tx is from one of our wallets (to confirm withdrawals)
        next unless contract_addresses.include?(contract_addresses) ||
          system_addresses.include?(address_from)

        @transactions += build_erc20_transactions(fetch_erc20_transaction tx.fetch('hash'))
      end
      @transactions
    rescue Ethereum::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    private

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
      Rails.logger.debug "Fetching tx receipt #{tx_id}"
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
      [
        {
          hash:           normalize_txid(block_txn.fetch('hash')),
          amount:         @amount_converter.call(block_txn.fetch('value').hex),
          from_addresses: [normalize_address(block_txn['from'])],
          to_address:     normalize_address(block_txn['to']),
          txout:          block_txn.fetch('transactionIndex').to_i(16),
          block_number:   block_txn.fetch('blockNumber').to_i(16),
          # currency_id:    currency.fetch(:id),
          status:         transaction_status(block_txn)
        }
      ]
    end

    def build_erc20_transactions(txn_receipt)
      # Build invalid transaction for failed withdrawals
      if transaction_status(txn_receipt) == 'fail' && txn_receipt.fetch('logs').blank?
        return build_invalid_erc20_transaction(txn_receipt)
      end

      txn_receipt.fetch('logs').each_with_object([]) do |log, formatted_txs|
        next if log['blockHash'].blank? && log['blockNumber'].blank?
        next if log.fetch('topics').blank? || log.fetch('topics')[0] != TOKEN_EVENT_IDENTIFIER

        contract_address = log.fetch('address')
        next unless contract_addresses.include? contract_address

        destination_address = normalize_address('0x' + log.fetch('topics').last[-40..-1])

        formatted_txs << build_erc20_transactions(
          hash:            normalize_txid(txn_receipt.fetch('transactionHash')),
          amount:          @amount_converter.call(log.fetch('data').hex, contract_address),
          from_addresses:  [normalize_address(txn_receipt['from'])],
          to_address:      destination_address,
          txout:           log['logIndex'].to_i(16),
          block_number:    txn_receipt.fetch('blockNumber').to_i(16),
          contract_address: log.fetch('address'),
          #currency_id:     currency.fetch(:id),
          status:          transaction_status(txn_receipt)
        )
      end
    end

    def build_invalid_erc20_transaction(txn_receipt)
      return unless contract_address.include? txn_receipt.fetch('to')

      {
        hash:         normalize_txid(txn_receipt.fetch('transactionHash')),
        block_number: txn_receipt.fetch('blockNumber').to_i(16),
        contract_address: txn_receipt.fetch('to'),
        #currency_id:  currency.fetch(:id),
        status:       transaction_status(txn_receipt),
      }
    end

    def transaction_status(block_txn)
      if block_txn.dig('status') == SUCCESS
        'success'
      elsif block_txn.dig('status') == FAILED
        'failed'
      else
        'pending'
      end
    end
  end
end
