class Peatio::Transaction
  def from_address=(value)
    self.from_addresses = [value]
  end

  def from_address
    raise "Transaction #{self.as_json} has multiply from_addresses" if from_addresses.many?
    from_addresses.take
  end
end
