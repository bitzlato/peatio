# frozen_string_literal: true

class TronGateway < AbstractGateway
  FEE_LIMIT = 10_000_000

  include TronGateway::Encryption
  include TronGateway::Estimation
  include TronGateway::AddressNormalizer
  include TronGateway::BalanceLoader
  include TronGateway::TransactionBuilder
  include TronGateway::TransactionFetcher
  include TronGateway::TransactionCreator
  include TronGateway::BlockFetcher
  include TronGateway::Collector
  include TronGateway::SunRefueler

  extend TronGateway::Encryption
  extend TronGateway::AddressNormalizer

  def build_client
    Tron::Client.new(blockchain.server)
  end

  def client_version; end

  def latest_block_number
    client.json_rpc(path: 'wallet/getblockbylatestnum', params: { num: 1 })
          .fetch('block')[0]['block_header']['raw_data']['number']
  end

  def create_address!(_secret = nil)
    key = Key.new
    blockchain_address = BlockchainAddress.create!(address: key.base58check_address, address_type: self.class.address_type, private_key_hex: key.private_hex)

    { address: blockchain_address.address }
  end

  def self.address_type
    :tron
  end

  private

  def fee_limits
    blockchain.blockchain_currencies.each_with_object({}) { |c, agg| agg[c.contract_address] = c.gas_limit }
  end

  def hot_wallet
    blockchain.hot_wallet || raise(NoHotWallet)
  end
end
