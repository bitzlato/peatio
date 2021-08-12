class AbstractGateway
  attr_reader :blockchain

  def self.case_sensitive?
    false
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

  def fetch_block(block_number)
    raise "not implemented #{self.class}"
  end

  private

  def build_client
    raise "not implemented #{self.class}"
  end
end
