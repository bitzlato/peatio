# frozen_string_literal: true

class TronGateway
  module Collector
    BANDWIDTH_PRICE = 10
    COLLECT_FACTOR = 1

    def collect!(payment_address)
      raise 'wrong blockchain' unless payment_address.blockchain_id == blockchain.id

      amounts = load_balances(payment_address.address)
                .select { |_currency, amount| amount_collectable?(amount) }
                .each_with_object({}) { |(_key, amount), hash| hash[amount.currency.contract_address] = amount.base_units }

      amounts.delete nil if amounts.many?
      amounts = amounts.freeze
      blockchain_address = payment_address.blockchain_address

      if amounts.any?
        logger.info("Collect from payment_address #{payment_address.address} amounts: #{amounts}")
        amounts.map do |contract_address, amount|
          create_transaction!(
            from_address: payment_address.address,
            to_address: hot_wallet.address,
            amount: amount,
            blockchain_address: blockchain_address,
            contract_address: contract_address
          )
        end
      else
        logger.warn("No collectable amount to collect from #{payment_address.address}")
      end
    end

    #
    # coin_address = is contract address for token or nil for native currency
    #
    def enough_gas_to_collect?(address)
      required_sun_balance_to_collect(address) <= fetch_balance(address)
    end
    alias has_enough_gas_to_collect? enough_gas_to_collect?

    # На адресе есть монеты, которые можно собрать (их ценность выше газа)
    #
    def collectable_balances?(address)
      collectable_coins(address).present?
    end
    alias has_collectable_balances? collectable_balances?

    private

    # total_required_trx - energy_remain - bandwidth_remains
    def required_sun_balance_to_collect(address)
      estimates = get_estimates(address)
      total_amount = collectable_coins(address).sum { |coin| sun_for_collection_in_money coin }
      total_amount -= energy_to_sun(estimates.energy_remains)
      total_amount -= bandwidth_to_sun(estimates.bandwidth_remains)
      total_amount = 0 if total_amount.negative?

      total_amount
    end

    # Returns array of collectable coins.
    # Collectable is coin with has enough amount to be collected (amount more than paid sun * COLLECT_FACTOR)
    def collectable_coins(address)
      coins = blockchain
              .currencies
              .select { |currency| amount_collectable?(load_balance(address, currency)) }
              .map(&:contract_address)

      # Don't return native currency if where are collectable tokens
      coins.many? ? coins.compact : coins
    end

    # На адресе есть монеты, которые можно собрать, их ценность выше газа?
    def amount_collectable?(amount)
      raise 'amount must be a Money' unless amount.is_a? Money

      return false if amount.zero?

      if amount.currency.token?
        amount.to_d >= [amount.currency.min_collection_amount, amount.currency.min_deposit_amount].max
      else
        amount >= sun_for_collection_in_money(nil) * COLLECT_FACTOR
      end
    end

    # energy * 280SUN
    def fetch_energy_price
      blockchain
        .fee_currency
        .to_money_from_units(
          client.json_rpc(path: 'wallet/getchainparameters')
            .fetch('chainParameter').index_by { |p| p['key'] }['getEnergyFee']['value']
        )
    end

    # transaction bytesize * 10SUN
    def fetch_bandwidth_price
      blockchain
        .fee_currency
        .to_money_from_units(BANDWIDTH_PRICE)
    end

    # for token convert energy and bandwidth to trx
    # for coin conver bandwidth to trx
    # return trx in money
    def sun_for_collection_in_money(coin_address)
      currency = blockchain
                 .currencies
                 .find { |c| c.contract_address == coin_address } ||
                 raise("No found currency with coin '#{coin_address || :native}' for blockchain #{blockchain.id}")

      if currency.token?
        energy_limit    = (currency.options['energy_limit'] || raise("No energylimit specified for currency #{currency.id}"))
        bandwidth_limit = (currency.options['bandwidth_limit'] || raise("No bandwidth_limit specified for currency #{currency.id}"))

        energy_to_sun(energy_limit) + bandwidth_to_sun(bandwidth_limit)
      else
        bandwidth_limit = (currency.options['bandwidth_limit'] || raise("No bandwidth_limit specified for currency #{currency.id}"))

        bandwidth_to_sun(bandwidth_limit)
      end
    end

    # conert energy to trx in money
    def energy_to_sun(amount)
      amount * fetch_energy_price
    end

    # conert bandwidth to trx in money
    def bandwidth_to_sun(amount)
      amount * fetch_bandwidth_price
    end
  end
end
