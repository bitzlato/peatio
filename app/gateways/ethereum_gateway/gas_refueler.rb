class EthereumGateway
  # Refuel address to have enough gas for future token's and ethereum transfer
  #
  class GasRefueler < AbstractCommand
    REFUEL_GAS_FACTOR = Settings.ethereum.refuel_gas_factor

    Error = Class.new StandardError
    NoReason = Class.new Error
    NoTokens = Class.new Error
    Balanced = Class.new Error

    def call(gas_wallet_address:, gas_wallet_secret:, target_address: , tokens_count: )
      ethereum_balance = load_basic_balance target_address
      raise "ethereum_balance #{ethereum_balance} must be an Integer" unless ethereum_balance.is_a? Integer

      raise NoTokens if tokens_count.zero?

      gas_limit = TransactionCreator::DEFAULT_ETH_GAS_LIMIT
      gas_price ||= (fetch_gas_price * REFUEL_GAS_FACTOR).to_i

      required_amount =  tokens_count * TransactionCreator::DEFAULT_ERC20_GAS_LIMIT * gas_price

      transaction_amount = required_amount - ethereum_balance

      raise Balanced if ethereum_balance > required_amount

      #if ethereum_balance < required_amount
        #logger.info("No reason to create gas refueling eth transaction #{gas_wallet_address} -> #{target_address}"\
                    #" ethereum_balance: #{ethereum_balance}, tokens_count: #{tokens_count},"\
                    #" required_amount: #{required_amount} gas_price:#{gas_price} gas_limit:#{gas_limit}"\
                    #" transaction amount: #{transaction_amount}"\
                    #"ethereum_balance(#{ethereum_balance} < required_amount(#{required_amount})")
        #raise AmountError, 'Current balance less then required'
      #end

      if transaction_amount.positive?
        logger.info("Create gas refueling eth transaction #{gas_wallet_address} -> #{target_address}"\
                    " ethereum_balance: #{ethereum_balance}, tokens_count: #{tokens_count},"\
                    " required_amount: #{required_amount} gas_price:#{gas_price} gas_limit:#{gas_limit}"\
                    " transaction amount: #{transaction_amount}")
      else
        logger.info("Skip creating gas refueling eth transaction (current amount is enough) #{gas_wallet_address} -> #{target_address}"\
                    " ethereum_balance: #{ethereum_balance}, tokens_count: #{tokens_count},"\
                    " required_amount: #{required_amount} gas_price:#{gas_price} gas_limit:#{gas_limit}"\
                    " transaction amount: #{transaction_amount}")
        raise AmountError, 'Current balance less then required'
        return nil
      end

      tx = TransactionCreator.new(client).create_eth_transaction!(
          amount:       transaction_amount,
          from_address: gas_wallet_address,
          secret:       gas_wallet_secret,
          to_address:   target_address,
          subtract_fee: false,
          gas_limit:    gas_limit,
          gas_price:    gas_price)
      tx.options.merge! gas_factor: REFUEL_GAS_FACTOR
      tx
    end

  end
end

