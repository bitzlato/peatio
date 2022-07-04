# frozen_string_literal: true

class SolanaGateway < AbstractGateway
  attr_reader :blockchain, :api

  delegate :load_balances, :load_balance, to: :balance_loader

  def initialize(blockchain)
    @blockchain = blockchain
    @api = Api.new(blockchain)
  end

  def balance_loader
    BalanceLoader.new(blockchain)
  end

  def find_or_create_token_account(owner_address, contract_address, signer)
    TokenAddressCreator.new(blockchain).find_or_create_token_account(owner_address, contract_address, signer)
  end

  def self.valid_address? address
    address.match?(/[1-9A-HJ-NP-Za-km-z]{32,44}/)
  end

  def self.address_type
    :solana
  end

  def self.private_key(private_key_hex)
    Solana::Key.new([private_key_hex].pack('H*'))
  end
end
