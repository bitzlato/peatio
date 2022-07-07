# frozen_string_literal: true

# Read about trc 20 energy consamption
# https://github.com/tronprotocol/java-tron/issues/2982#issuecomment-856627675

class TronGateway < AbstractGateway
  include TronGateway::Encryption
  include TronGateway::AddressNormalizer
  include TronGateway::BalanceLoader

  extend TronGateway::Encryption
  extend TronGateway::AddressNormalizer

  IDLE_TIMEOUT = 1

  def build_client
    client_options = (blockchain.client_options || {}).symbolize_keys
                                                      .slice(:idle_timeout, :read_timeout, :open_timeout)
                                                      .reverse_merge(idle_timeout: IDLE_TIMEOUT)

    Tron::Client.new(blockchain.server, **client_options)
  end

  def self.address_type
    :tron
  end

  def self.private_key(private_key_hex)
    Eth::Key.new(priv: private_key_hex)
  end
end
