# frozen_string_literal: true

# Read about trc 20 energy consamption
# https://github.com/tronprotocol/java-tron/issues/2982#issuecomment-856627675

class TronGateway < AbstractGateway
  include TronGateway::Encryption
  include TronGateway::AddressNormalizer

  extend TronGateway::Encryption
  extend TronGateway::AddressNormalizer

  def self.address_type
    :tron
  end

  def self.private_key(private_key_hex)
    Eth::Key.new(priv: private_key_hex)
  end
end
