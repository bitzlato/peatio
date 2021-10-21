# frozen_string_literal: true

class EthereumGateway
  module CollectionConcern
    # Collect money only if there are balance more than the amount to payed gas
    #
    COLLECT_FACTOR = 2
    GAS_PRICE_EXPIRES = 60
    DEFAULT_GAS_FACTOR = 1.05

    # Collects tokens and native currency to hot wallet address
    #
    # It runs when we know that we have enough money to pay gase
    # and have tokens or money to collect
    #
    def collect!(payment_address)
      raise 'wrong blockchain' unless payment_address.blockchain_id == blockchain.id

      amounts = load_balances(payment_address.address)
                .select { |currency, amount| (is_amount_collectable?(amount) && (!payment_address.blockchain.allowance_enabled || (payment_address.blockchain.allowance_enabled && payment_address.fee_wallet_approved?(currency.id)))) }
                .each_with_object({}) { |(_key, amount), hash| hash[amount.currency.contract_address] = amount.base_units }

      # Remove native currency if there are tokens to transfer
      # We want to collect native currency when there are no collectable tokens in address
      amounts.delete nil if amounts.many?
      amounts = amounts.freeze
      blockchain_address = payment_address.blockchain_address
      if amounts.any?
        logger.info("Collect from payment_address #{payment_address.address} amounts: #{amounts}")
        if payment_address.blockchain.allowance_enabled
          EthereumGateway::AllowanceCollector
            .new(client)
            .call(from_address: payment_address.address,
                  to_address: hot_wallet.address,
                  amounts: amounts,
                  spender_address: fee_wallet.address,
                  spender_secret: fee_wallet.secret,
                  blockchain_address: fee_wallet.blockchain_address,
                  gas_limits: gas_limits,
                  gas_factor: gas_factor)
        else
          EthereumGateway::Collector
            .new(client)
            .call(from_address: payment_address.address,
                  to_address: hot_wallet.address,
                  amounts: amounts,
                  gas_limits: gas_limits,
                  gas_factor: gas_factor,
                  blockchain_address: blockchain_address,
                  secret: payment_address.secret,
                  chain_id: blockchain.chain_id)
        end
      else
        logger.warn("No collectable amount to collect from #{payment_address.address}")
      end
    end

    #
    # coin_address = is contract address for token or nil for native currency
    #
    def has_enough_gas_to_collect?(address)
      required_gas_balance_to_collect(address) <= fetch_balance(address)
    end

    # На адресе есть монеты, которые можно собрать (их ценность выше газа)
    #
    def has_collectable_balances?(address)
      collectable_coins(address).present?
    end

    private

    def required_gas_balance_to_collect(address)
      collectable_coins(address)
        .sum { |coin| gas_for_collection_in_money coin }
    end

    # Returns array of collectable coins.
    # Collectable is coin with has enough amount to be collected (amount more than paid gas * COLLECT_FACTOR)
    def collectable_coins(address)
      coins = blockchain
              .currencies
              .select { |currency| is_amount_collectable?(load_balance(address, currency)) }
              .map(&:contract_address)

      # Don't return native currency if where are collectable tokens
      coins.many? ? coins.compact : coins
    end

    # На адресе есть монеты, которые можно собрать, их ценность выше газа?
    def is_amount_collectable?(amount)
      raise 'amount must be a Money' unless amount.is_a? Money

      if amount.currency.token?
        amount.to_d >= [amount.currency.min_collection_amount, amount.currency.min_deposit_amount].max
      else
        amount >= gas_for_collection_in_money(nil) * COLLECT_FACTOR
      end
    end

    def gas_for_collection_in_money(coin_address)
      currency = blockchain
                 .currencies
                 .find { |c| c.contract_address == coin_address } ||
                 raise("No found currency with coin '#{coin_address || :native}' for blockchain #{blockchain.id}")

      gas_factor * fetch_gas_price * (currency.gas_limit || raise("No gas limit specified for currency #{currency.id}"))
    end

    # Returns current gas price in money
    def fetch_gas_price
      blockchain
        .fee_currency
        .to_money_from_units(
          # мы не можем кешировать, потому что при сборе газ посчитается из ноды и будет
          # другой. Нужно или при сборе брать газ из кэша или тут убрать. Я пока убрал тут.
          # Rails.cache.fetch([blockchain.id, :gas_price].join(':'), expires_in: GAS_PRICE_EXPIRES) do
          AbstractCommand.new(client).fetch_gas_price
        )
    end

    def gas_factor
      blockchain.client_options[:gas_factor] || DEFAULT_GAS_FACTOR
    end
  end
end
