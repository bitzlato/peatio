class EthereumGateway
  # Refuel address to have enough gas for future token's and ethereum transfer
  #
  class GasRefueler < AbstractCommand
    Error = Class.new StandardError
    NoTokens = Class.new Error
    Balanced = Class.new Error

    def call(gas_wallet_address:, gas_wallet_secret:, gas_limit: nil, gas_price: nil, gas_factor:, target_address: , contract_addresses: )
      balance_on_target_address = load_basic_balance target_address
      raise "balance_on_target_address #{balance_on_target_address} must be an Integer" unless balance_on_target_address.is_a? Integer

      if contract_addresses.empty?
        logger.info("No tokens on address #{target_address}")
        raise NoTokens
      end

      gas_price ||= (fetch_gas_price * gas_factor).to_i

      required_gas = contract_addresses.map do |contract_address|
        estimate_gas(from: gas_wallet_address, to: contract_address, gas_price: gas_price)
      end.sum

      transcation_gas_limit ||= estimate_gas from: gas_wallet_address, to: target_address, gas_price: gas_price

      required_amount = required_gas * gas_price + transcation_gas_limit * gas_price
      if balance_on_target_address >= required_amount
        logger.info("No reason to create gas refueling eth transaction #{gas_wallet_address} -> #{target_address}"\
                    " balance_on_target_address: #{balance_on_target_address}, contract_addresses: #{contract_addresses},"\
                    " required_amount: #{required_amount}")
        raise Balanced
      end

      transaction_amount = required_amount - balance_on_target_address
      logger.info("Create gas refueling eth transaction #{gas_wallet_address} -> #{target_address}"\
                  " balance_on_target_address: #{balance_on_target_address}, contract_addresses: #{contract_addresses},"\
                  " required_gas: #{required_gas}, gas_price:#{gas_price} transcation_gas_limit:#{transcation_gas_limit}"\
                  " transaction amount: #{transaction_amount} = required_gas * gas_price - balance_on_target_address")

      tx = TransactionCreator.new(client).create_eth_transaction!(
          amount:       transaction_amount,
          from_address: gas_wallet_address,
          secret:       gas_wallet_secret,
          to_address:   target_address,
          subtract_fee: false,
          gas_limit:    transcation_gas_limit,
          gas_price:    gas_price)
      tx.options.merge! gas_factor: gas_factor, required_amount: required_amount, required_gas: required_gas
      tx
    end
  end
end

