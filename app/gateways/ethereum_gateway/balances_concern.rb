# frozen_string_literal: true

class EthereumGateway
  module BalancesConcern
    def load_balances(address)
      blockchain
        .currencies
        .each_with_object({}) do |currency, a|
        a[currency.id] = load_balance(address, currency)
      end
    end

    # @return balance of addrese in Money
    def load_balance(address, currency)
      currency = currency.currency_record if currency.is_a? Money::Currency
      contract_address = BlockchainCurrency.find_by(blockchain: blockchain, currency: currency)&.contract_address
      BalanceLoader
        .new(client)
        .call(address, contract_address)
        .yield_self { |amount| currency.to_money_from_units(amount) }
    end

    # Returns native balance in money
    def fetch_balance(address)
      address = address.address if address.is_a? PaymentAddress
      blockchain.native_currency.to_money_from_units(
        AbstractCommand.new(client).load_basic_balance(address)
      )
    end
  end
end
