class AbstractGateway
  attr_reader :blockchain

  def self.normalize_address(address)
    # self.address = CashAddr::Converter.to_cash_address(address) if gateway.supports_cash_addr_format?
    #if blockchain.supports_cash_addr_format? && rid? && CashAddr::Converter.is_valid?(rid)
      #self.rid = CashAddr::Converter.to_cash_address(rid)
    #end
    address
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

  attr_reader :client

  def latest_block_number
    nil
  end

  def initialize(blockchain)
    @blockchain = blockchain
    @client = build_client
  end

  def enable_personal_address_balance?
    true
  end

  def enable_block_fetching?
    false
  end

  def supports_cash_addr_format?
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

  def save_transaction(transaction, extra = {})
    raise 'transaction must be a Peatio::Transaction' unless transaction.is_a? Peatio::Transaction
    Transaction.create!(
      {
        from_address: transaction.from_address,
        to_address: transaction.to_address,
        currency_id: transaction.currency_id,
        txid: transaction.txid,
        block_number: transaction.block_number,
        amount: transaction.amount,
        status: transaction.status,
        txout: transaction.txout
      }.merge(extra)
    )
  end

  def hash_to_transaction(hash)
    return if hash.nil?
    if hash.is_a? Peatio::Transaction
      currency = blockchain.find_money_currency(hash.contract_address)
      hash.dup.tap do |t|
        t.currency_id = currency.id
        t.amount = currency.to_money_from_units hash.amount
      end.freeze
    else
      currency = blockchain.find_money_currency(hash.fetch(:contract_address))
      Peatio::Transaction.new(hash.merge(currency_id: currency.id, amount: currency.to_money_from_units(hash.fetch(:amount)))).freeze
    end
  end

  def build_client
    not_implemented!
  end

  def not_implemented!
    raise "not implemented #{self.class}"
  end
end
