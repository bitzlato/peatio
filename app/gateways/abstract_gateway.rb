# frozen_string_literal: true

class AbstractGateway
  attr_reader :blockchain, :client

  def self.address_type
    nil
  end

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

  def initialize(blockchain)
    @blockchain = blockchain
    @client = build_client
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

  def build_client
    not_implemented!
  end

  def not_implemented!
    raise "not implemented #{self.class}"
  end
end
