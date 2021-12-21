# frozen_string_literal: true

class TronGateway
  module TransactionBuilder
    DEFAULT_FEATURES = { case_sensitive: true, cash_addr_format: false }.freeze
    TOKEN_EVENT_IDENTIFIER = 'ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'

    private

    def build_transaction(tx_hash, txn_receipt)
      case tx_hash['raw_data']['contract'][0]['type']
      when 'TransferContract'
        build_coin_transaction(tx_hash, txn_receipt)
      when 'TriggerSmartContract'
        build_trc20_transactions(tx_hash, txn_receipt)
      end
    end

    def build_trc20_transactions(tx_hash, txn_receipt)
      contract         = tx_hash.dig('raw_data', 'contract')[0]
      contract_value   = contract.dig('parameter', 'value')
      from_address     = reformat_encode_address(contract_value['owner_address'])
      to_address       = reformat_encode_address("41#{contract_value['data'][32..71]}")
      contract_address = reformat_encode_address(contract_value['contract_address'])

      return [] unless blockchain.contract_addresses.include?(contract_address)
      return [] if !blockchain.follow_addresses.intersect?([from_address, to_address].to_set) && blockchain.follow_txids.exclude?(txn_receipt.fetch('id'))
      return [build_invalid_trc20_transaction(tx_hash, txn_receipt)] if trc20_transaction_status(txn_receipt) == 'failed' && txn_receipt.fetch('log', []).blank?

      txn_receipt.fetch('log', []).filter_map do |log, index|
        next if log.fetch('topics', []).blank? || log.fetch('topics')[0] != TOKEN_EVENT_IDENTIFIER

        contract_address = reformat_encode_address("41#{log.fetch('address')}")
        from_address = reformat_encode_address("41#{log.fetch('topics')[-2][-40..]}")
        to_address = reformat_encode_address("41#{log.fetch('topics').last[-40..]}")

        next unless blockchain.contract_addresses.include?(contract_address)
        next unless blockchain.follow_addresses.intersect?([from_address, to_address].to_set)

        { hash: txn_receipt.fetch('id'),
          amount: log.fetch('data').hex,
          from_addresses: [from_address],
          to_address: to_address,
          contract_address: contract_address,
          txout: index,
          block_number: txn_receipt['blockNumber'],
          options: txn_receipt.fetch('receipt', {}).merge(tx_hash.fetch('raw_data', {}).slice('fee_limit')),
          fee: txn_receipt['fee'],
          status: trc20_transaction_status(txn_receipt) }
      end
    end

    def build_coin_transaction(tx_hash, txn_receipt)
      tx = tx_hash['raw_data']['contract'][0]

      from_address = reformat_encode_address(tx['parameter']['value']['owner_address'])
      to_address = reformat_encode_address(tx['parameter']['value']['to_address'])

      return if !blockchain.follow_addresses.intersect?([from_address, to_address].to_set) && !blockchain.follow_txids.exclude?(txn_receipt.fetch('id'))

      { hash: tx_hash['txID'],
        amount: tx['parameter']['value']['amount'],
        from_addresses: [reformat_encode_address(tx['parameter']['value']['owner_address'])],
        to_address: reformat_encode_address(tx['parameter']['value']['to_address']),
        txout: 0,
        block_number: txn_receipt['blockNumber'],
        options: txn_receipt.fetch('receipt', {}),
        fee: txn_receipt['fee'],
        status: 'success' }
    end

    def build_invalid_trc20_transaction(tx_hash, txn_receipt)
      contract = tx_hash.dig('raw_data', 'contract')[0]
      contract_value = contract.dig('parameter', 'value')

      contract_address = reformat_encode_address(contract_value['contract_address'])
      from_address = reformat_encode_address(contract_value['owner_address'])
      to_address = reformat_encode_address("41#{contract_value['data'][32..71]}")

      { hash: tx_hash.fetch('txID'),
        block_number: txn_receipt['blockNumber'],
        contract_address: contract_address,
        from_addresses: [from_address],
        to_address: to_address,
        amount: 0,
        options: txn_receipt.fetch('receipt', {}).merge(tx_hash.fetch('raw_data', {}).slice('fee_limit')),
        fee: txn_receipt['fee'],
        status: trc20_transaction_status(tx_hash) }
    end

    def trc20_transaction_status(txn_receipt)
      txn_receipt['receipt']['result'] == 'SUCCESS' ? 'success' : 'failed'
    end

    def invalid_transaction?(txn)
      txn['raw_data']['contract'][0]['parameter']['value']['amount'].to_i.zero? \
         || txn['ret'][0]['contractRet'] == 'REVERT'
    end

    def invalid_trc20_transaction?(txn_receipt)
      txn_receipt.fetch('contract_address', '').blank? \
         || txn_receipt.fetch('log', []).blank?
    end
  end
end
