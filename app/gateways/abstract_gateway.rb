class AbstractGateway
  attr_reader :blockchain

  def self.supports_cash_addr_format?
    false
  end

  def self.normalize_address(address)
    # self.address = CashAddr::Converter.to_cash_address(address) if gateway.supports_cash_addr_format?
    #if blockchain.supports_cash_addr_format? && rid? && CashAddr::Converter.is_valid?(rid)
      #self.rid = CashAddr::Converter.to_cash_address(rid)
    #end
    address
  end

  def self.format_address(address)
    not_implemented!
  end

  def self.normalize_txid(txid)
    txid
  end

  def self.case_sensitive?
    not_implemented!
  end

  def self.valid_address?(address)
    # CashAddr::Converter.is_valid?(rid)
    not_implemented!
  end

  def self.implements?(method_name)
    instance_methods(false).include?(method_name)
  end

  def self.enable_personal_address_balance?
    true
  end

  attr_reader :client

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

  def support_wallet_kind?(kind)
    true # TODO
  end

  def case_sensitive?
    self.class.case_sensitive?
  end

  def name
    self.class.name
  end

  def fetch_block_transactions(block_number)
    raise "not implemented #{self.class}"
  end

  private

  def logger
    Rails.logger
  end

  def kind_of_transaction(tx)
    raise 'tx must be a Peatio::Transcation' unless tx.is_a? Peatio::Transaction
    if tx.to_address.in?(blockchain.deposit_addresses)
      if tx.from_address.in?(blockchain.wallets_addresses)
        :gas_refuel
      else
        :deposit
      end
    elsif tx.from_address.in?(blockchain.wallets_addresses)
      :withdraw
    else
      :unknown
    end
  end

  def monefy_transaction(hash, extras = {})
    return if hash.nil?
    if hash.is_a? Peatio::Transaction
      currency = blockchain.find_money_currency(hash.contract_address)
      raise "Sourced transaction must be plain #{hash}" if hash.amount.is_a? Money
      hash.dup.tap do |t|
        t.currency_id = currency.id
        t.blockchain_id = blockchain.id
        t.amount = currency.to_money_from_units hash.amount
        t.fee_currency_id = blockchain.fee_currency.money_currency.id
        t.fee = hash.fee.nil? ? nil : blockchain.fee_currency.money_currency.to_money_from_units(hash.fee)
        t.kind = kind_of_transaction(t)
      end.freeze
    else
      currency = blockchain.find_money_currency(hash.fetch(:contract_address))
      Peatio::Transaction.new(
        hash.merge(
          currency_id: currency.id,
          amount: currency.to_money_from_units(hash.fetch(:amount)),
          fee: hash.fetch(:fee, nil) ? blockchain.fee_currency.money_currency.to_money_from_units(hash.fetch(:fee)) : nil,
          fee_currency_id: blockchain.fee_currency.money_currency.id,
          blockchain_id: blockchain.id,
        )
      ).tap do |t|
        t.kind = kind_of_transaction(t)
      end.freeze
    end
  end

  def build_client
    not_implemented!
  end

  def not_implemented!
    raise "not implemented #{self.class}"
  end
end
