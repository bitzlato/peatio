# frozen_string_literal: true

# Proxy to Ethereum.
#
# Converts amounts from money to ethereum base units.
# Knows about peatio database models.
#
class EthereumGateway < AbstractGateway
  include NumericHelpers
  extend Concern
  include BalancesConcern

  IDLE_TIMEOUT = 1

  Error = Class.new StandardError
  NoHotWallet = Class.new Error

  def self.address_type
    :ethereum
  end

  def self.private_key(private_key_hex)
    Eth::Key.new(priv: private_key_hex)
  end

  private

  def build_client
    client_options = (blockchain.client_options || {}).symbolize_keys
                                                      .slice(:idle_timeout, :read_timeout, :open_timeout)
                                                      .reverse_merge(idle_timeout: IDLE_TIMEOUT)

    ::Ethereum::Client.new(blockchain.server, **client_options)
  end
end
