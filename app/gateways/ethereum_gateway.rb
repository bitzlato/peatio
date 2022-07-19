# frozen_string_literal: true

# Proxy to Ethereum.
#
# Converts amounts from money to ethereum base units.
# Knows about peatio database models.
#
class EthereumGateway < AbstractGateway
  extend Concern

  IDLE_TIMEOUT = 1

  Error = Class.new StandardError
  NoHotWallet = Class.new Error

  def self.address_type
    :ethereum
  end

  def self.private_key(private_key_hex)
    Eth::Key.new(priv: private_key_hex)
  end
end
