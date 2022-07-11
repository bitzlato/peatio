# frozen_string_literal: true

# Proxy to Tron.

class TronGateway
  module AddressNormalizer
    TRON_START_BYTE = '41'

    def valid_address?(address)
      !!normalize_address(address)
    end

    def normalize_address(address)
      address = address.to_s
      address = reformat_encode_address(address) if address.start_with?(TRON_START_BYTE)
      return address if valid_base58_address?(address)
    end

    def normalize_txid(txid)
      return nil if txid.nil?

      txid.to_s
    end

    private

    def valid_base58_address?(base58address)
      address_bytes = Base58.base58_to_binary(base58address, :bitcoin)
      signature = address_bytes[-4..]
      address = address_bytes[..20]
      checksum = (Digest::SHA256.digest(Digest::SHA256.digest(address)))[...4]

      checksum == signature
    end
  end
end
