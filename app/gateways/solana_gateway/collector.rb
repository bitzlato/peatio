class SolanaGateway
  class Collector < Base
    COLLECT_FACTOR = 2

    Error = Class.new StandardError
    NoAmounts = Class.new StandardError

    def has_collectable_balances?(address)
      collectable_coins(address).present?
    end

    def is_amount_collectable? amount
      amount.to_d >= [amount.currency.min_collection_amount, amount.currency.blockchain_currency_record.min_deposit_amount].max
    end

    def collectable_coins(address)
      coins = blockchain
                .blockchain_currencies
                .select { |bc| is_amount_collectable?(gateway.load_balance(address, bc.currency)) }
                .map(&:contract_address)

      # Don't return native currency if where are collectable tokens
      coins.many? ? coins.compact : coins
    end

    def collect! payment_address
      raise 'wrong blockchain' unless payment_address.blockchain_id == blockchain.id

      amounts = gateway.load_balances(payment_address.address)
                  .select { |_currency, amount| is_amount_collectable?(amount) }
                  .each_with_object({}) do |(_key, amount), hash|
        contract_address = BlockchainCurrency.find_by(blockchain: blockchain, currency: amount.currency.currency_record)&.contract_address
        hash[contract_address] = amount#.base_units
      end

      amounts = Hash[*amounts.first].freeze # Don't send simultaneous transactions for same address

      if amounts.any?
        logger.info("Collect from payment_address #{payment_address.address} amounts: #{amounts}")
        collect_amounts({
          payment_address: payment_address,
          amounts: amounts
        })
      else
        logger.warn("No collectable amount to collect from #{payment_address.address}")
      end
    end

    private

    # Collect all tokens and coins from payment_address to hot wallet
    def collect_amounts(payment_address:, amounts:)
      raise NoAmounts if amounts.empty?

      # raise 'Must be secret or blockchain_address' if secret.nil? && blockchain_address.nil?

      amounts.filter_map do |contract_address, amount|
        raise 'amount must be Money' unless amount.is_a? Money # not money

        # not collectiong native from token_account
        next if payment_address.blockchain_currency.present? and contract_address.nil?

        next unless amount.base_units.positive?

        to_address = currency_hot_wallet(amount.currency.currency_record)
        logger.info("Collect #{amount.base_units} of #{contract_address || :native} from #{payment_address.address} to #{to_address}")
        transaction = TransactionCreator.new(blockchain).perform({
                        from_address: payment_address.address,
                        to_address: to_address.address,
                        amount: amount,
                        fee_payer_address: native_hot_wallet(amount.currency.currency_record).address,
                        contract_address: contract_address,
                        signers: signers(payment_address, amount)
                      })
        logger.info("Collect transaction created #{transaction.as_json}")
        transaction.txid
        # TODO: Save CollectRecord with transaction dump
      rescue SolanaGateway::TransactionCreator::Error => e
        report_exception e, true, payment_address_id: payment_address.id, currency: currency
        logger.warn("Errored collecting #{currency} #{amount.base_units} from address #{payment_address.address} with #{e}")
        nil
      end
    end

    def native_hot_wallet currency
      bc = BlockchainCurrency.find_by(blockchain: blockchain, currency: currency)
      blockchain.withdraw_wallet_for_currency(bc.parent_currency)
    end

    def currency_hot_wallet currency
      blockchain.withdraw_wallet_for_currency(currency)
    end

    def signers payment_address, amount
      parent_address = payment_address.parent ? payment_address.parent : payment_address

      [native_hot_wallet(amount.currency.currency_record).private_key, parent_address.private_key]
    end
  end
end
