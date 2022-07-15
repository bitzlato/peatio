# frozen_string_literal: true

class BitcoinGateway < AbstractGateway
  def self.case_sensitive?
    true
  end

  def self.valid_address?(address)
    AdequateCryptoAddress.valid? address, :btc
  end

  def self.normalize_address(address)
    AdequateCryptoAddress.address(address, :btc).address
  end
end
