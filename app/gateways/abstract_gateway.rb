class AbstractGateway
  attr_reader :blockchain

  def self.implements?(method_name)
    instance_methods(false).include?(method_name)
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
    true
  end

  def name
    self.class.name
  end

  private

  def build_client
    raise 'not implemented'
  end
end
