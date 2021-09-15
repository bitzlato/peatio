# frozen_string_literal: true

require_relative 'abstract_command'
class EthereumGateway
  class BalanceLoader < AbstractCommand
    def call(address, contract_address = nil)
      if contract_address.present?
        load_erc20_balance(address, contract_address)
      else
        load_basic_balance(address)
      end
    end

    def load_erc20_balance(address, contract_address)
      data = abi_encode('balanceOf(address)', normalize_address(address))
      client.json_rpc(:eth_call, [{ to: contract_address, data: data }, 'latest'])
            .hex
            .to_i
    end
  end
end
