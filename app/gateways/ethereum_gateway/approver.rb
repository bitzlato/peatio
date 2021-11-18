# frozen_string_literal: true

class EthereumGateway
  class Approver < AbstractCommand
    Error = Class.new StandardError
    ALLOWANCE_AMOUNT = (2**256) - 1

    def call(from_address:,
             spender:,
             secret:,
             gas_limit:,
             contract_address:,
             nonce: nil,
             gas_price: nil,
             gas_factor: 1)
      raise 'No gas limit' if gas_limit.nil?

      gas_price ||= (fetch_gas_price * gas_factor).to_i
      raise 'gas price zero' if gas_price.zero?

      logger.info(message: 'Create approval transaction', from_address: from_address, spender: spender, contract_address: contract_address, gas_price: gas_price, gas_limit: gas_limit)
      params = [{
        from: normalize_address(from_address),
        nonce: nonce.nil? ? nil : '0x' + nonce.to_i.to_s(16),
        to: contract_address,
        data: abi_encode('approve(address,uint256)', normalize_address(spender), '0x' + ALLOWANCE_AMOUNT.to_s(16)),
        gas: '0x' + gas_limit.to_i.to_s(16),
        gasPrice: '0x' + gas_price.to_i.to_s(16)
      }.compact, secret]
      validate_txid!(client.json_rpc(:personal_sendTransaction, params))
    end
  end
end
