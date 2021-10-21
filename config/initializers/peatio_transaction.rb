# frozen_string_literal: true

class Peatio::Transaction
  alias_attribute :id, :hash
  alias_attribute :txid, :hash
  attr_accessor :contract_address, :fee, :fee_currency_id, :blockchain_id, :to, :from, :topic

  #  %w[success pending failed rejected].freeze
  def status=(s)
    raise "Unknown status #{s}" unless STATUSES.include? s.to_s

    @status = s.to_s
  end

  def from_address=(value)
    self.from_addresses = [value]
  end

  def from_address
    raise "Transaction #{as_json} has multiply from_addresses" if Array(from_addresses).many?

    from_addresses.try(:first)
  end
end
