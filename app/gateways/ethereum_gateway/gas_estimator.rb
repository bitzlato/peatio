class EthereumGateway
  class GasEstimator < AbstractCommand
    Error = Class.new StandardError

    def call(from_address: , to_addresses:,  gas_price: nil, gas_factor: 1 )
      gas_price ||= (fetch_gas_price * gas_factor).to_i

      estimated_gas = to_addresses.map do |address|
        estimate_gas(from: from_address, to: address, gas_price: gas_price)
      end.sum

      logger.info("Estimated gas for transaction from #{from_address} to #{to_addresses.join(', ')} is #{estimated_gas} with gas_price: #{gas_price}")

      estimated_gas*gas_price
    end
  end
end
