# frozen_string_literal: true

class TronGateway
  module Encryption
    extend ActiveSupport::Concern

    ALGO = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

    def reformat_encode_address(hexstring)
      sha256 = sha256_encode(sha256_encode(hexstring))
      (hexstring + sha256[0, 8]).hex.digits(58).reverse.map { |i| ALGO[i] }.join
    end

    private

    def sha256_encode(hexstring)
      Digest::SHA256.hexdigest([hexstring].pack('H*'))
    end

    def base58_to_int(base58_val)
      int_val = 0
      base58_val.reverse.chars.each_with_index do |char, index|
        char_index = ALGO.index(char)
        int_val += char_index * (ALGO.length**index)
      end
      int_val
    end

    def base58_to_binary(base58_val)
      int_encode_hex(base58_to_int(base58_val))[0, 42]
    end

    def int_encode_hex(int)
      hex = int.to_s(16)
      hex.length.even? ? hex : ('0' + hex)
    end
  end
end
