module Tron
  class Blockchain < Peatio::Blockchain::Abstract

    UndefinedCurrencyError = Class.new(StandardError)

    TOKEN_EVENT_IDENTIFIER = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
    SUCCESS = 'SUCCESS'
    FAILED = '0x0'

    DEFAULT_FEATURES = { case_sensitive: false, cash_addr_format: false }.freeze

    def initialize(custom_features = {})
      @features = DEFAULT_FEATURES.merge(custom_features).slice(*SUPPORTED_FEATURES)
      @settings = {}
    end

    def configure(settings = {})
      # Clean client state during configure.
      @client = nil
      @trc20 = []; @trx = []
      @whitelisted_addresses = if settings[:whitelisted_addresses].present?
                                 settings[:whitelisted_addresses].pluck(:address).to_set
                               else
                                 []
                               end

      @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))
      @settings[:currencies]&.each do |c|
        if c.dig(:options, :trc20_contract_address).present?
          @trc20 << c
        else
          @trx << c
        end
      end
    end

    def fetch_block!(block_number)
      block_json = client.json_rpc(:getblockbynum, num: block_number)

      if block_json.blank? || block_json['transactions'].blank?
        return Peatio::Block.new(block_number, [])
      end
      block_json.fetch('transactions').each_with_object([]) do |tx, block_arr|
        next unless tx.fetch('ret')[0]["contractRet"] == "SUCCESS"

        if tx.fetch('raw_data')["contract"][0]["type"] == 'TransferContract'
          next if invalid_trx_transaction?(tx)

        elsif tx.fetch('raw_data')["contract"][0]["type"] == 'TriggerSmartContract'
          next if @trc20.find do |c|
            # Check `to` and `input` options to find erc-20 smart contract contract 
            c.dig(:options, :trc20_contract_address) == normalize_address(tx.fetch('raw_data')["contract"][0]["parameter"]["value"]["contract_address"])
            # Check if `to` in whitelisted smart contracts
          end.blank?
        end

        txs = build_transactions(tx, block_number).map do |ntx|
          Peatio::Transaction.new(ntx)
        end

        block_arr.append(*txs)
      end.yield_self { |block_arr| Peatio::Block.new(block_number, block_arr) }
    rescue Tron::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    def latest_block_number
      client.get_json_rpc(:getnowblock).fetch('block_header')['raw_data']['number']
    rescue Tron::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    def load_balance_of_address!(address, currency_id)
      currency = settings[:currencies].find { |c| c[:id] == currency_id.to_s }
      raise UndefinedCurrencyError unless currency

      if currency.dig(:options, :trc20_contract_address).present?
        load_trc20_balance(address, currency)
      else
        client.json_rpc(:eth_getBalance, [normalize_address(address), 'latest'])
              .hex
              .to_d
              .yield_self { |amount| convert_from_base_unit(amount, currency) }
      end
    rescue Ethereum::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    def fetch_transaction(transaction)
      currency = settings[:currencies].find { |c| c.fetch(:id) == transaction.currency_id }
      return if currency.blank?
      txn_receipt = client.json_rpc(:eth_getTransactionReceipt, [transaction.hash])
      if currency.in?(@trx)
        txn_json = client.json_rpc(:eth_getTransactionByHash, [transaction.hash])
        attributes = {
          amount: convert_from_base_unit(txn_json.fetch('value').hex, currency),
          to_address: normalize_address(txn_json['to']),
          txout: txn_json.fetch('transactionIndex').to_i(16),
          status: transaction_status(txn_receipt)
        }
      else
        if transaction.txout.present?
          txn_json = txn_receipt.fetch('logs').find { |log| log['logIndex'].to_i(16) == transaction.txout }
        else
          txn_json = txn_receipt.fetch('logs').first
        end
        attributes = {
          amount: convert_from_base_unit(txn_json.fetch('data').hex, currency),
          to_address: normalize_address('0x' + txn_json.fetch('topics').last[-40..-1]),
          status: transaction_status(txn_receipt)
        }
      end
      transaction.assign_attributes(attributes)
      transaction
    end

    private

    def load_trc20_balance(address, currency)
      data = abi_encode('balanceOf(address)', normalize_address(address))
      client.json_rpc(:eth_call, [{ to: contract_address(currency), data: data }, 'latest'])
            .hex
            .to_d
            .yield_self { |amount| convert_from_base_unit(amount, currency) }
    end

    def client
      @client ||= Tron::Client.new(settings_fetch(:server))
    end

    def settings_fetch(key)
      @settings.fetch(key) { raise Peatio::Blockchain::MissingSettingError, key.to_s }
    end

    def normalize_txid(txid)
      txid
      # txid.try(:downcase)
    end

    def normalize_address(address)
      address
      # address.try(:downcase)
    end

    def build_transactions(tx_hash, block_number)
      if tx_hash.fetch('raw_data')["contract"][0]["type"] == 'TriggerSmartContract'
        build_trc20_transactions(tx_hash, block_number)
      else
        build_trx_transactions(tx_hash, block_number)
      end
    end

    def build_trx_transactions(block_txn, block_number)
      item = fetch('raw_data')["contract"]
      @trx.map do |currency|
        { hash: normalize_txid(block_txn.fetch('txID')),
          amount: convert_from_base_unit(item['parameter']['value']['amount'].to_d, currency),
          from_addresses: [normalize_address(item['parameter']['value']['owner_address'])],
          to_address: normalize_address(item['parameter']['value']['to_address']),
          txout: 0,
          block_number: block_number,
          currency_id: currency.fetch(:id),
          status: transaction_status(block_txn) }
      end
    end

    def parse_trc20_transfer_data(params_value)
      data = params_value['data']
      tokenAddress = params_value['contract_address']
      fromAddress = params_value['owner_address']
      return unless data.length == 136
      return unless data[0..7] == TRC20TRANSFER_IDENTITY
      toAddress = base58_address('41' + data[32..71])
      amount = data[-64..-1].to_i(16).to_d
      return [tokenAddress, fromAddress, toAddress, amount]
    end

    def build_trc20_transactions(txn_receipt, block_number)
      # Build invalid transaction for failed withdrawals
      if transaction_status(txn_receipt) == 'fail'
        return build_invalid_trc20_transaction(txn_receipt)
      end

      item = fetch('raw_data')["contract"]
      ret = parse_trc20_transfer_data(item['parameter']['value'])
      return [] if ret[0]
      # Skip if ERC20 contract address doesn't match.
      currencies = @trc20.select { |c| c.dig(:options, :trc20_contract_address) == ret[0] }
      return [] if currencies.blank?

      destination_address = ret[2]

      currencies.each do |currency, formatted_txs|
        formatted_txs << { hash: normalize_txid(block_txn.fetch('txID')),
                           amount: convert_from_base_unit(log.fetch('data').hex, currency),
                           from_addresses: [ret[1]],
                           to_address: destination_address,
                           txout: 0,
                           block_number: block_number,
                           currency_id: currency.fetch(:id),
                           status: transaction_status(txn_receipt) }
      end
    end

    def build_invalid_trc20_transaction(txn_receipt)
      currencies = @trc20.select { |c| c.dig(:options, :trc20_contract_address) == txn_receipt.fetch('to') }
      return if currencies.blank?

      currencies.each_with_object([]) do |currency, invalid_txs|
        invalid_txs << { hash: normalize_txid(txn_receipt.fetch('transactionHash')),
                         block_number: txn_receipt.fetch('blockNumber').to_i(16),
                         currency_id: currency.fetch(:id),
                         status: transaction_status(txn_receipt) }
      end
    end

    def transaction_status(block_txn)
      if block_txn.fetch('ret')[0]["contractRet"] == SUCCESS
        'success'
      else
        'failed'
      end
    end

    def invalid_trx_transaction?(block_txn)
      # @todo later
      false
    end

    def contract_address(currency)
      normalize_address(currency.dig(:options, :trc20_contract_address))
    end

    def abi_encode(method, *args)
      '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
        data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
      end
    end

    def convert_from_base_unit(value, currency)
      value.to_d / currency.fetch(:base_factor).to_d
    end
  end
end
