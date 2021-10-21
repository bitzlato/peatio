# frozen_string_literal: true

class EthereumGateway
  class AllowanceCollector < AbstractCommand
    Error = Class.new StandardError
    NoAmounts = Class.new StandardError

    # Collect all tokens and coins from payment_address to hot wallet
    def call(from_address:, to_address:, amounts:, spender_address:, spender_secret:, blockchain_address:, gas_limits:, chain_id:, gas_factor: 1)
      raise NoAmounts if amounts.empty?

      amounts.filter_map do |contract_address, amount|
        raise 'amount must be an Integer' unless amount.is_a? Integer # not money
        next unless amount.positive?

        logger.info("Collect #{amount} of #{contract_address || :native} from #{from_address} to #{to_address}")
        FromTransferer
          .new(client)
          .call(from_address: spender_address,
                secret: spender_secret,
                blockchain_address: blockchain_address,
                contract_address: contract_address,
                sender: from_address,
                recipient: to_address,
                amount: amount,
                gas_limit: gas_limits[contract_address] || raise("No gas limit for #{contract_address}"),
                chain_id: chain_id,
                gas_factor: gas_factor)
      end
    end
  end
end
