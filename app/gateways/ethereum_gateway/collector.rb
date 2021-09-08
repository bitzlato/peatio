class EthereumGateway
  # Refuel address to have enough gas for future token's and ethereum transfer
  #
  class Collector < AbstractCommand
    Error = Class.new StandardError
    NoAmounts = Class.new StandardError

    # Collect all tokens and coins from payment_address to hot wallet
    def call(from_address:, to_address: , amounts:, secret:, gas_factor: 1 )
      raise NoAmounts if amounts.empty?

      # TODO Сообщать о том что не хватает газа ДО выполнения, так как он потратися
      # Не выводить базовую валюту пока не счету есть токены
      # Базовую валюту откидывать за вычетом необходимой суммы газа для токенов
      #
      amounts.map do |contract_address, amount|
        raise unless amount.is_a? Integer # not money
        logger.info("Collect #{amount} of #{contract_address || :native} from #{from_address} to #{to_address}")
        transaction  = TransactionCreator
          .new(client)
          .call(from_address: from_address,
                to_address: to_address,
                amount: amount,
                secret: secret,
                gas_factor: gas_factor,
                contract_address: contract_address,
                subtract_fee: contract_address.nil?
               )
        logger.info("Collect transaction created #{transaction.as_json}")
        transaction.txid
        # TODO Save CollectRecord with transaction dump
      rescue EthereumGateway::TransactionCreator::Error => err
        report_exception err, true, payment_address_id: payment_address.id, currency: currency
        logger.warn("Errored collecting #{currency} #{amount} from address #{payment_address.address} with #{err}")
        nil
      end.compact
    end
  end
end
