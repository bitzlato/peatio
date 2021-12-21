# frozen_string_literal: true

class TronGateway
  module BalanceLoader
    def load_balances(address)
      blockchain
        .currencies
        .each_with_object({}) do |currency, a|
        a[currency.id] = load_balance(address, currency)
      end
    end

    def load_balance(address, currency)
      if currency.contract_address.present?
        load_trc20_balance(address, currency.contract_address)
      else
        load_basic_balance(address)
      end.yield_self { |amount| currency.to_money_from_units(amount.to_i) }
    rescue Tron::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    def fetch_balance(address)
      address = address.address if address.is_a? PaymentAddress

      blockchain.native_currency.to_money_from_units(
        load_basic_balance(address)
      )
    end

    private

    def load_trc20_balance(address, contract_address)
      client.json_rpc(path: 'wallet/triggersmartcontract',
                      params: {
                        owner_address: reformat_decode_address(address),
                        contract_address: reformat_decode_address(contract_address),
                        function_selector: 'balanceOf(address)',
                        parameter: abi_encode(reformat_decode_address(address)[2..42])
                      }).fetch('constant_result')[0].hex
    end

    def load_basic_balance(address)
      client.json_rpc(path: 'wallet/getaccount',
                      params: { address: reformat_decode_address(address) }).fetch('balance', nil)
    end
  end
end
