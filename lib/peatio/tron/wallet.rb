module Tron
  class Wallet < Peatio::Wallet::Abstract

    DEFAULT_ETH_FEE = { gas_limit: 21_000, gas_price: :standard }.freeze

    DEFAULT_ERC20_FEE = { gas_limit: 90_000, gas_price: :standard }.freeze

    DEFAULT_FEATURES = { skip_deposit_collection: false }.freeze

    GAS_PRICE_THRESHOLDS = { standard: 1, safelow: 0.9, fast: 1.1 }.freeze

    def initialize(custom_features = {})
      @features = DEFAULT_FEATURES.merge(custom_features).slice(*SUPPORTED_FEATURES)
      @settings = {}
    end

    def configure(settings = {})
      # Clean client state during configure.
      @client = nil

      @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

      @wallet = @settings.fetch(:wallet) do
        raise Peatio::Wallet::MissingSettingError, :wallet
      end.slice(:uri, :address, :secret)

      @currency = @settings.fetch(:currency) do
        raise Peatio::Wallet::MissingSettingError, :currency
      end.slice(:id, :base_factor, :options)
    end

    def create_address!(options = {})
      ret = get_json_rpc(:generateaddress)
      { address: ret['address'], secret: ret['privateKey'] }
    rescue Tron::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    def create_transaction!(transaction, options = {})
      if @currency.dig(:options, :trc20_contract_address).present?
        create_trc20_transaction!(transaction)
      else
        create_trx_transaction!(transaction, options)
      end
    rescue Tron::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    def prepare_deposit_collection!(transaction, deposit_spread, deposit_currency)
      # Don't prepare for deposit_collection in case of eth deposit.
      return [] if deposit_currency.dig(:options, :trc20_contract_address).blank?
      return [] if deposit_spread.blank?

      options = DEFAULT_ERC20_FEE.merge(deposit_currency.fetch(:options).slice(:gas_limit, :gas_price))

      options[:gas_price] = calculate_gas_price(options)

      # We collect fees depending on the number of spread deposit size
      # Example: if deposit spreads on three wallets need to collect eth fee for 3 transactions
      fees = convert_from_base_unit(options.fetch(:gas_limit).to_i * options.fetch(:gas_price).to_i)
      transaction.amount = fees * deposit_spread.size
      transaction.options = options

      [create_trx_transaction!(transaction)]
    rescue Ethereum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    def load_balance!
      if @currency.dig(:options, :trc20_contract_address).present?
        load_trc20_balance(@wallet.fetch(:address))
      else
        client.json_rpc(:getaccount, address: _address).fetch('balance')
              .to_d
              .yield_self { |amount| convert_from_base_unit(amount) }
      end
    rescue Ethereum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    private

    def load_trc20_balance(address)
      parameter = abi_encode(hex_address(address))
      ret = client.json_rpc(:triggerconstantcontract,
                            contract_address: @currency.trc20_contract_address,
                            owner_address: _address,
                            function_selector: "balanceOf(address)",
                            parameter: parameter
      )
      ret['constant_result'][0].to_i(16)
                               .to_d
                               .yield_self { |amount| convert_from_base_unit(amount) }
    end

    def hex_address(base58Address)
      binaryCheckSum = Base58.base58_to_binary(base58Address, :bitcoin)
      addcheckSum = binaryCheckSum.unpack("H*").first
      address = addcheckSum[0..-9]
      address
    end

    def create_trx_transaction!(transaction, options = {})
      currency_options = @currency.fetch(:options).slice(:gas_limit, :gas_price)
      options.merge!(DEFAULT_ETH_FEE, currency_options)

      amount = convert_to_base_unit(transaction.amount)

      if transaction.options.present?
        options[:gas_price] = transaction.options[:gas_price]
      else
        options[:gas_price] = calculate_gas_price(options)
      end

      # Subtract fees from initial deposit amount in case of deposit collection
      # amount -= options.fetch(:gas_limit).to_i * options.fetch(:gas_price).to_i if options.dig(:subtract_fee)

      txdata = client.json_rpc(:createtransaction,

                             owner_address: normalize_address(@wallet.fetch(:address)),
                             to_address: normalize_address(transaction.to_address),
                             amount: amount
      )
      getTransactionSign = client.json_rpc(:gettransactionsign, transaction: txdata, privateKey: @wallet.fetch(:secret))
      ret = json_rpc(:broadcasttransaction, getTransactionSign)


      unless valid_txid?(normalize_txid(txid))
        raise Tron::Client::Error, \
              "Withdrawal from #{@wallet.fetch(:address)} to #{transaction.to_address} failed."
      end
      # Make sure that we return currency_id
      transaction.currency_id = 'trx' if transaction.currency_id.blank?
      transaction.amount = convert_from_base_unit(amount)
      transaction.hash = normalize_txid(ret['txid'])
      transaction.options = options
      transaction
    end

    def create_trc20_transaction!(transaction, options = {})
      # currency_options = @currency.fetch(:options).slice(:gas_limit, :gas_price, :trc20_contract_address)
      currency_options = @currency.fetch(:options).slice(:trc20_contract_address)
      # options.merge!(DEFAULT_ERC20_FEE, currency_options)
      options.merge!(currency_options)

      amount = convert_to_base_unit(transaction.amount)
      parameter = abi_encode(hex_address(transaction.to_address).slice(2..-1), amount.to_s(16))
      txdata = client.json_rpc(:triggersmartcontract,
                        contract_address: options[:trc20_contract_address],
                        function_selector: "transfer(address,uint256)",
                        owner_address: @wallet.fetch(:address),
                        call_value: 0,
                        fee_limit: 40000000,
                        call_token_value: 0,
                        token_id: 0,
                        parameter: parameter
      )

      return unless txdata["result"]["result"] == true
      getTransactionSign = client.json_rpc(:gettransactionsign, transaction: txdata["transaction"], privateKey:  @wallet.fetch(:secret))
      ret = client.json_rpc(:broadcasttransaction, getTransactionSign)

      unless valid_txid?(normalize_txid(txid))
        raise Tron::Client::Error, \
              "Withdrawal from #{@wallet.fetch(:address)} to #{transaction.to_address} failed."
      end
      transaction.hash = normalize_txid(ret['txid'])
      transaction.options = options
      transaction
    end

    def normalize_address(address)
      address.downcase
    end

    def normalize_txid(txid)
      txid.downcase
    end

    def contract_address
      normalize_address(@currency.dig(:options, :trc20_contract_address))
    end

    def valid_txid?(txid)
      txid.to_s.match?(/\A0x[A-F0-9]{64}\z/i)
    end

    def abi_encode(method, *args)
      args.each_with_object([]) do |arg, data|
        data.push arg.rjust(64, '0')
      end.join
    end

    def convert_from_base_unit(value)
      value.to_d / @currency.fetch(:base_factor)
    end

    def convert_to_base_unit(value)
      x = value.to_d * @currency.fetch(:base_factor)
      unless (x % 1).zero?
        raise Peatio::Wallet::ClientError,
              "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " \
            "#{value.to_d} - #{x.to_d} must be equal to zero."
      end
      x.to_i
    end

    def calculate_gas_price(options = { gas_price: :standard })
      # Get current gas price
      gas_price = client.json_rpc(:eth_gasPrice, [])
      Rails.logger.info { "Current gas price #{gas_price.to_i(16)}" }

      # Apply thresholds depending on currency configs by default it will be standard
      (gas_price.to_i(16) * GAS_PRICE_THRESHOLDS.fetch(options[:gas_price].try(:to_sym), 1)).to_i
    end

    def client
      uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
      @client ||= Client.new(uri, idle_timeout: 1)
    end
  end
end