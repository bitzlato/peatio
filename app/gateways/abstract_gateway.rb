# frozen_string_literal: true

class AbstractGateway
  attr_reader :blockchain

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

  def self.implements?(method_name)
    instance_methods(false).include?(method_name)
  end

  def initialize(blockchain)
    @blockchain = blockchain
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

  def not_implemented!
    raise "not implemented #{self.class}"
  end
end
