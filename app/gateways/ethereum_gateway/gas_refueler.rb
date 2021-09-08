class EthereumGateway
  # Refuel address to have enough gas for future token's and ethereum transfer
  #
  class GasRefueler < AbstractCommand
    Error = Class.new StandardError
    NoTokens = Class.new Error
    Balanced = Class.new Error

    def call(gas_wallet_address:, gas_wallet_secret:, base_gas_limit:, token_gas_limit:, gas_factor:, target_address: , tokens_count: )
      ethereum_balance = load_basic_balance target_address
      raise "ethereum_balance #{ethereum_balance} must be an Integer" unless ethereum_balance.is_a? Integer

      if tokens_count.zero?
        logger.info("No tokens on address #{target_address}")
        raise NoTokens
      end

      gas_price ||= (fetch_gas_price * gas_factor).to_i

      gas_limit = base_gas_limit || estimate_gas(
        from: gas_wallet_address,
        to: target_address,
        gas_price: gas_price,
      )

      # TODO Определять автоматически в зависимости от вида токена
      token_gas_limit = 100_000

      transaction_amount = tokens_count * token_gas_limit * gas_price - ethereum_balance

      if transaction_amount.positive?
        logger.info("Create gas refueling eth transaction #{gas_wallet_address} -> #{target_address}"\
                    " ethereum_balance: #{ethereum_balance}, tokens_count: #{tokens_count},"\
                    " gas_price:#{gas_price} gas_limit:#{gas_limit} token_gas_limit:#{token_gas_limit}"\
                    " transaction amount: #{transaction_amount} = tokens_count * token_gas_limit * gas_price - ethereum_balance")
      else
        logger.info("No reason to create gas refueling eth transaction #{gas_wallet_address} -> #{target_address}"\
                    " ethereum_balance: #{ethereum_balance}, tokens_count: #{tokens_count},"\
                    " gas_price:#{gas_price} gas_limit:#{gas_limit} token_gas_limit:#{token_gas_limit}"\
                    " transaction amount: #{transaction_amount}")
        raise Balanced
      end

      tx = TransactionCreator.new(client).create_eth_transaction!(
          amount:       transaction_amount,
          from_address: gas_wallet_address,
          secret:       gas_wallet_secret,
          to_address:   target_address,
          subtract_fee: false,
          gas_limit:    gas_limit,
          gas_price:    gas_price)
      tx.options.merge! gas_factor: gas_factor
      tx
    end

  end
end

