# frozen_string_literal: true

class SolanaGateway
  class Base
    attr_reader :blockchain

    delegate :gateway, to: :blockchain
    delegate :api, to: :gateway

    def initialize blockchain
      @blockchain = blockchain
    end

    def logger
      Rails.logger
    end

    def monefy_transaction(hash, _extras = {})
      return if hash.nil?

      if hash.is_a? Peatio::Transaction
        raise "Sourced transaction must be plain #{hash}" if hash.amount.is_a? Money

        tx = hash
      else
        tx = Peatio::Transaction.new(hash)
      end
      currency = blockchain.find_money_currency(tx.contract_address)
      tx.dup.tap do |tx|
        tx.currency_id = currency.currency_record.id
        tx.blockchain_id = blockchain.id
        tx.amount = currency.to_money_from_units tx.amount
        tx.fee_currency_id = blockchain.fee_blockchain_currency.currency_id
        tx.fee = tx.fee.nil? ? nil : blockchain.fee_blockchain_currency.money_currency.to_money_from_units(tx.fee)
        tx.to = kind_of_address(tx.to_address)
        tx.from = kind_of_address(tx.from_address)
      end.freeze
    end

    def kind_of_address(address)
      if address.is_a?(Enumerable)
        raise 'multiple addresses' if address.many?

        address = address.first
      end
      return :wallet if address.in? blockchain.wallets_addresses
      return :deposit if address.in? blockchain.deposit_addresses

      :unknown
    end
  end
end