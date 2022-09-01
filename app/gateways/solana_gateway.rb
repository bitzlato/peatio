# frozen_string_literal: true

class SolanaGateway < AbstractGateway
  attr_reader :blockchain

  def initialize(blockchain)
    @blockchain = blockchain
  end

  def self.valid_address? address
    address.match?(/[1-9A-HJ-NP-Za-km-z]{32,44}/)
  end

  def self.address_type
    :solana
  end
end
