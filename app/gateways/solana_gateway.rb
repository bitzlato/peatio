# frozen_string_literal: true

class SolanaGateway < AbstractGateway
  attr_reader :blockchain, :api

  delegate :latest_block_number, :client_version, to: :api
  delegate :load_balances, :load_balance, to: :balance_loader
  delegate :has_collectable_balances?, :is_amount_collectable?, :collect!, to: :collector

  def initialize(blockchain)
    @blockchain = blockchain
    @api = Api.new(blockchain)
  end

  def balance_loader
    BalanceLoader.new(blockchain)
  end

  def enable_block_fetching?
    true
  end

  def create_address!(secret = nil)
    AddressCreator.perform(secret)
  end

  def fetch_block_transactions(slot_id)
    BlockFetcher.new(blockchain).perform(slot_id)
  end

  # def fetch_transaction txid, txout
  #   monefy_transaction(
  #     TransactionFetcher.new(client).call(txid)
  #   )
  # end

  def collector
    Collector.new(blockchain)
  end

  def has_enough_gas_to_collect?(address)
    true
  end

  def refuel_gas!(target_address)
    raise 'No refueling!'
  end

  def create_transaction!(from_address:,
                          to_address:,
                          amount:,
                          blockchain_address: nil,
                          contract_address: nil,
                          subtract_fee: false, # nil means auto
                          nonce: nil,
                          gas_factor: nil,
                          meta: {}, **)

    raise 'amount must be a Money' unless amount.is_a? Money

    monefy_transaction(
      TransactionCreator
        .new(blockchain)
        .perform(
          from_address: from_address,
          to_address: to_address,
          amount: amount,
          fee_payer_address: blockchain_address.address,
          signers: [self.class.private_key(blockchain_address.private_key_hex)],
          contract_address: contract_address,
          # subtract_fee: subtract_fee.nil? ? contract_address.nil? : subtract_fee,
        )
    )
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

  def blocks_to_process(from_block)
    api.get_blocks_with_limit(from_block)
  end
end
