require 'ws/ethereum'

module Ethereum
  class WalletAbstract < Peatio::Wallet::Abstract
    extend WS::Ethereum
    include WS::Ethereum::Helpers

    DEFAULT_ETH_FEE = { gas_limit: 21_000, gas_price: :standard }.freeze

    DEFAULT_ERC20_FEE = { gas_limit: 90_000, gas_price: :standard }.freeze

    DEFAULT_FEATURES = { skip_deposit_collection: false }.freeze

    GAS_SPEEDS = { standard: 1, safelow: 0.9, fast: 1.1 }.freeze

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
      end.slice(:id, :base_factor, :min_collection_amount, :options)
    end

    # Transfer fee from fee-wallet to deposit-addres before spreading
    #
    def prepare_deposit_collection!(transaction, deposit_spread, deposit_currency)
      # Don't prepare for deposit_collection in case of eth deposit.
      return [] if deposit_currency.dig(:options, contract_address_option).blank?
      return [] if deposit_spread.blank?

      options = DEFAULT_ERC20_FEE.merge(deposit_currency.fetch(:options).slice(:gas_limit, :gas_price))

      options[:gas_price] = calculate_gas_price(options)

      # We collect fees depending on the number of spread deposit size
      # Example: if deposit spreads on three wallets need to collect eth fee for 3 transactions
      fees = convert_from_base_unit(options.fetch(:gas_limit).to_i * options.fetch(:gas_price).to_i,
                                    @currency.fetch(:base_factor))
      amount = fees * deposit_spread.size

      # If fee amount is greater than min collection amount
      # system will detect fee collection as deposit
      # To prevent this system will raise an error
      min_collection_amount = @currency.fetch(:min_collection_amount).to_d
      if amount > min_collection_amount
        raise Ethereum::Client::Error, \
              "Fee amount(#{amount}) is greater than min collection amount(#{min_collection_amount})."
      end

      transaction.amount = amount
      transaction.options = options

      [create_eth_transaction!(transaction)]
    rescue Ethereum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    protected

    def client
      uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
      @client ||= Client.new(uri, idle_timeout: 1)
    end
  end
end
