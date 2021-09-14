class EthereumGateway
  class AbstractCommand
    include NumericHelpers
    include Concern

    STATUS_SUCCESS = '0x1'
    STATUS_FAILED = '0x0'
    ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
    TOKEN_EVENT_IDENTIFIER = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'

    attr_reader :client

    def initialize(client)
      @client = client || raise('No gateway client')
    end

    # ex calculate_gas_price
    def fetch_gas_price
      client.json_rpc(:eth_gasPrice, []).to_i(16).tap do |gas_price|
        Rails.logger.info { "Fetched gas price #{gas_price}" }
      end
    end

    def fetch_receipt(tx_id)
      # logger.debug "Fetching tx receipt #{tx_id}"
      tx = client.json_rpc(:eth_getTransactionReceipt, [tx_id])
      return if tx.nil? || tx.fetch('to').blank?

      tx
    end

    def client_version
      client.json_rpc(:web3_clientVersion)
    end

    def estimate_gas(from:, to:, gas_price: nil, value: nil, data: nil)
      gas_price ||= fetch_gas_price
      logger.info("estimate_gas from #{from} to #{to} value #{value} data #{data} gas_price #{gas_price}")
      raise 'dont send value and data in same time' if value.present? && data.present?

      estimage_gas = client.json_rpc(:eth_estimateGas, [{
        gasPrice: '0x' + gas_price.to_i.to_s(16),
        from: normalize_address(from),
        to: normalize_address(to),
        # No reasone to send it because of possible exception 'insufficient funds for transfer'
        value: value.nil? ? nil : '0x' + value.to_i.to_s(16),
        data: data
      }.compact]).to_i(16)
      logger.info("estimate_gas #{from}->#{to} with value=#{value || :nil} and data=#{data || :nil} is #{estimage_gas}")
      estimage_gas
    end

    def load_basic_balance(address)
      client.json_rpc(:eth_getBalance, [normalize_address(address), 'latest'])
            .hex
            .to_i
    end

    private

    def build_erc20_transactions(txn_receipt, block_txn, contract_addresses: nil, follow_addresses: nil, follow_txids: nil, follow_txouts: nil)
      txid = normalize_txid(txn_receipt.fetch('transactionHash'))
      from_address = normalize_address(txn_receipt['from'])

      if txn_receipt.fetch('logs').blank?
        return [] unless follow_addresses.nil? || follow_addresses.include?(from_address) ||
                         (follow_txids.present? && follow_txids.include?(txid))

        # Build invalid transaction for failed withdrawals
        return [build_invalid_erc20_transaction(txn_receipt, block_txn)]
      end

      txn_receipt.fetch('logs').each_with_object([]) do |log, formatted_txs|
        next if log['blockHash'].blank? && log['blockNumber'].blank?
        next if log.fetch('topics').blank? || log.fetch('topics')[0] != TOKEN_EVENT_IDENTIFIER

        contract_address = log.fetch('address')
        next unless contract_addresses.nil? || contract_addresses.include?(contract_address)

        to_address = normalize_address('0x' + log.fetch('topics').last[-40..])

        next unless follow_addresses.nil? || follow_addresses.include?(to_address) || follow_addresses.include?(from_address) ||
                    (follow_txids.present? && follow_txids.include?(txid))

        txout = log['logIndex'].to_i(16)
        next unless follow_txouts.nil? || follow_txouts.include?(txout)

        # BSC has no effectiveGasPrice key
        gas_price = txn_receipt.fetch('effectiveGasPrice', block_txn.fetch('gasPrice')).to_i(16)
        gas_used = txn_receipt.fetch('gasUsed').to_i(16)
        formatted_txs << {
          hash: txid,
          amount: log.fetch('data').hex,
          from_addresses: [from_address],
          to_address: to_address,
          txout: txout,
          block_number: txn_receipt.fetch('blockNumber').to_i(16),
          contract_address: log.fetch('address'),
          status: transaction_status(txn_receipt),
          options: { gas_price: gas_price, gas_used: gas_used },
          fee: gas_price * gas_used
        }
      end
    end

    def invalid_eth_transaction?(block_txn)
      block_txn.fetch('to').blank? \
        || (block_txn.fetch('value').hex.to_d <= 0 && block_txn.fetch('input').hex <= 0)
    end

    # The usual case is a function call transfer(address,uint256) with footprint 'a9059cbb'
    def get_addresses_from_input(input)
      # Check if one of the first params of the function call is one of our deposit addresses
      Set.new(
        ["0x#{input[34...74]}", "0x#{input[75...115]}"].tap do |to_address|
          to_address.delete(ZERO_ADDRESS)
        end
      )
    end

    def build_invalid_erc20_transaction(txn_receipt, block_txn)
      # Some invalid transaction has no effectiveGasPrice
      # For example: https://bscscan.com/tx/0x014fd1e933ddfdb1bc44617408e75ee12b656f7d54e7eaf176ae3fd2b92cf401
      #
      gas_used = txn_receipt.fetch('gasUsed').to_i(16)
      gas_price = txn_receipt.fetch('effectiveGasPrice', block_txn.fetch('gasPrice')).to_i(16)

      {
        hash: normalize_txid(txn_receipt.fetch('transactionHash')),
        block_number: txn_receipt.fetch('blockNumber').to_i(16),
        contract_address: txn_receipt.fetch('to'),
        from_addresses: [normalize_address(txn_receipt['from'])],
        amount: 0,
        status: transaction_status(txn_receipt),
        fee: gas_price * gas_used,
        options: { gas_price: gas_price, gas_used: gas_used, gas_limit: block_txn.fetch('gas').to_i(16) }
      }
    end

    def build_success_eth_transaction(txn_receipt, block_txn, validate_txout = nil)
      txid = normalize_txid(block_txn.fetch('hash'))
      txout = block_txn.fetch('transactionIndex').to_i(16)
      logger.warn("Transcation #{txid} has wrong txout #{txout}<>#{validate_txout}") if validate_txout.present? && txout != validate_txout
      gas_used = txn_receipt.fetch('gasUsed').to_i(16)
      gas_price = txn_receipt.fetch('effectiveGasPrice', block_txn.fetch('gasPrice')).to_i(16)

      {
        hash: txid,
        amount: block_txn.fetch('value').hex,
        from_addresses: [normalize_address(block_txn['from'])],
        to_address: normalize_address(block_txn['to']),
        txout: txout,
        block_number: block_txn.fetch('blockNumber').to_i(16),
        status: 'success',
        options: { gas_price: gas_price, gas_used: gas_used, gas_limit: block_txn.fetch('gas').to_i(16) },
        fee: gas_price * gas_used,
        contract_address: nil
      }
    end

    def transaction_status(block_txn)
      if block_txn['status'] == STATUS_SUCCESS
        Transaction::SUCCESS_STATUS
      elsif block_txn['status'] == STATUS_FAILED
        Transaction::FAIL_STATUS
      else
        Transaction::PENDING_STATUS
      end
    end

    def logger
      Rails.logger
    end
  end
end
