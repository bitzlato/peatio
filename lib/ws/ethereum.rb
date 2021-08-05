module WS
  module Ethereum
    require_relative 'ethereum/helpers'
    require_relative 'ethereum/balance_loader'
    require_relative 'ethereum/address_creator'
    require_relative 'ethereum/transaction_creator'

    IDLE_TIMEOUT = 1

    def load_balance(uri, address, currency)
      BalanceLoader
        .new(build_client(uri))
        .call(address, currency.base_factor, currency.contract_address)
    end

    def create_address!(uri, secret = nil)
      AddressCreator
        .new(build_client(uri))
        .call(address, currency.base_factor, currency.contract_address)
    end

    def create_transaction(from_address:, to_address:, amount:, secret: , contract_address: nil, subtract_fee: false)
      TransactionCreator
        .new(build_client(uri), secret)
        .call(from_address: from_address,
              to_address: to_address,
              amount: amount,
              contract_address: contract_address,
              subtract_fee: subtract_fee)
    end

    private

    def build_client(uri)
      ::Ethereum::Client.new(uri, idle_timeout: IDLE_TIMEOUT)
    end
  end
end
