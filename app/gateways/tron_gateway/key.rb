# frozen_string_literal: true

# How to sign: https://developers.tron.network/v4.3.0/docs/account#algorithm
#
class TronGateway
  class Key
    attr_reader :private_key, :public_key

    def initialize(priv: nil)
      @private_key = MoneyTree::PrivateKey.new key: priv
      @public_key = MoneyTree::PublicKey.new @private_key, compressed: false
    end

    def private_hex
      private_key.to_hex
    end

    def public_bytes
      public_key.to_bytes
    end

    def public_hex
      public_key.to_hex
    end

    def hex_address
      address_bytes.unpack1('H*')
    end

    def address_bytes
      "\x41" + Digest::SHA3.new(256).digest(public_bytes[1..])[-20..]
    end

    def signature
      (Digest::SHA256.digest(Digest::SHA256.digest(address_bytes)))[...4]
    end

    def base58check_address
      Base58.binary_to_base58((address_bytes + signature).force_encoding('BINARY'), :bitcoin, true)
    end
  end
end
