class EthereumGateway
  class GasEstimator < AbstractCommand
    Error = Class.new StandardError

    DEFAULT_AMOUNT = 1

    def call(from_address:, to_address:, contract_addresses: [], account_native: false, gas_price: nil, gas_factor: 1 )
      gas_price ||= (fetch_gas_price * gas_factor).to_i

      estimated_gas = contract_addresses.map do |address|
        data = abi_encode('transfer(address,uint256)', normalize_address(to_address), '0x' + DEFAULT_AMOUNT.to_s(16))
        estimate_gas(from: from_address, to: address, gas_price: gas_price, data: data)
      end.sum

      estimated_gas += estimate_gas(from: from_address, to: to_address, gas_price: gas_price) if account_native

      logger.info("Estimated gas for transaction from #{from_address} to #{contract_addresses.join(', ')} and to_address:#{to_address} is #{estimated_gas} with gas_price: #{gas_price}")

      estimated_gas * gas_price
    end
  end
end
