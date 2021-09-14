# frozen_string_literal: true

class BitcoinCashGateway < AbstractGateway
  def self.format_address(address, format)
    address = AdequateCryptoAddress.address(address, :bch)
    case format
    when 'legacy' then address.legacy_address
    when 'cash' then address.cash_address
    else
      raise "Unknown address format #{format}"
    end
  end
end
