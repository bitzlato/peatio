class Peatio::Transaction
  alias_attribute :id, :hash
  alias_attribute :txid, :hash
  attr_accessor :contract_address

  def from_address=(value)
    self.from_addresses = [value]
  end

  def from_address
    raise "Transaction #{self.as_json} has multiply from_addresses" if Array(from_addresses).many?
    from_addresses.try(:first)
  end
end
