# frozen_string_literal: true

class AbstractGateway
  attr_reader :blockchain, :client

  def self.supports_cash_addr_format?
    false
  end

  def self.normalize_address(address)
    # self.address = CashAddr::Converter.to_cash_address(address) if gateway.supports_cash_addr_format?
    # if blockchain.supports_cash_addr_format? && rid? && CashAddr::Converter.is_valid?(rid)
    # self.rid = CashAddr::Converter.to_cash_address(rid)
    # end
    address
  end

  def self.format_address(_address)
    not_implemented!
  end

  def self.normalize_txid(txid)
    txid
  end

  def self.case_sensitive?
    not_implemented!
  end

  def self.valid_address?(_address)
    # CashAddr::Converter.is_valid?(rid)
    not_implemented!
  end

  def self.valid_txid?(_txid)
    not_implemented
  end

  def self.implements?(method_name)
    instance_methods(false).include?(method_name)
  end

  def self.enable_personal_address_balance?
    true
  end

  def self.supports_allowance?
    false
  end

  def self.supports_invoice?
    false
  end

  def latest_block_number
    nil
  end

  def initialize(blockchain)
    @blockchain = blockchain
    @client = build_client
  end

  def enable_block_fetching?
    false
  end

  def support_wallet_kind?(_kind)
    true # TODO
  end

  def case_sensitive?
    self.class.case_sensitive?
  end

  def name
    self.class.name
  end

  def fetch_block_transactions(_block_number)
    raise "not implemented #{self.class}"
  end

  private

  def logger
    Rails.logger
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
      tx.currency_id = currency.id
      tx.blockchain_id = blockchain.id
      tx.amount = currency.to_money_from_units tx.amount
      tx.fee_currency_id = blockchain.fee_currency.money_currency.id
      tx.fee = tx.fee.nil? ? nil : blockchain.fee_currency.money_currency.to_money_from_units(tx.fee)
      tx.to = kind_of_address(tx.to_address)
      tx.from = kind_of_address(tx.from_address)
    end.freeze
  end

  def build_client
    not_implemented!
  end

  def not_implemented!
    raise "not implemented #{self.class}"
  end
end
