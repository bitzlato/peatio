# frozen_string_literal: true

class TronGateway
  module Encryption
    extend ActiveSupport::Concern

    ALGO = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

    def reformat_decode_address(address)
      base58_to_binary(address)
    end

    def reformat_encode_address(hexstring)
      sha256 = sha256_encode(sha256_encode(hexstring))
      (hexstring + sha256[0, 8]).hex.digits(58).reverse.map { |i| ALGO[i] }.join
    end

    def encode_hex(str)
      str.unpack1('H*')
    end

    def decode_hex(str)
      [str].pack('H*')
    end

    def abi_encode(*args)
      args.each_with_object(+'') do |arg, data|
        data.concat(arg.delete_prefix('0x').rjust(64, '0'))
      end
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
