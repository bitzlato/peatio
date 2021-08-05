require_relative 'abstract_service'

module WS
  module Ethereum
    class BalanceLoader < AbstractService
      def call(address, base_factor, contract_address = nil)
        if contract_address.present?
          load_erc20_balance(address, base_factor, contract_address)
        else
          load_basic_balance(address, base_factor)
        end
      rescue Ethereum::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      def load_basic_balance(address, base_factor)
        client.json_rpc(:eth_getBalance, [normalize_address(address), 'latest'])
          .hex
          .to_d
          .yield_self { |amount| convert_from_base_unit(amount, base_factor) }
      end

      def load_erc20_balance(address, base_factor, contract_address)
        data = abi_encode('balanceOf(address)', normalize_address(address))
        client.json_rpc(:eth_call, [{ to: contract_address, data: data }, 'latest'])
          .hex
          .to_d
          .yield_self { |amount| convert_from_base_unit(amount, base_factor) }
      end
    end
  end
end
