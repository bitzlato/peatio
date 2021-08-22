class EthereumGateway
  class BlockFetcher < AbstractCommand
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

    def build_erc20_transactions(txn_receipt)
      super txn_receipt, contract_addresses: contract_addresses, follow_addresses: follow_addresses, follow_txids: follow_txids
    end

    def build_invalid_erc20_transaction(txn_receipt)
      return unless contract_addresses.include? txn_receipt.fetch('to')
      super txn_receipt
    end
  end
end
