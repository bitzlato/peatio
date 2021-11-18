# frozen_string_literal: true

class EthereumGateway
  module EstimationGasConcern
    def estimated_gas(contract_addresses:, account_native:, gas_limits: {})
      contract_addresses = contract_addresses.compact
      raise 'No contract addresses and no account_native' unless contract_addresses.any? || account_native

      estimated_gas = contract_addresses.sum do |address|
        gas_limits[address] || raise("Unknown gas limit for #{address}")
      end
      estimated_gas += (gas_limits[nil] || raise('Unknown gas limit for native')) if account_native
      estimated_gas
    end
  end
end
