# frozen_string_literal: true

class BitzlatoGateway < AbstractGateway
  def self.valid_address?(address)
    return false if BitcoinGateway.valid_address?(address)

    # Take regexp from p2p, but increase length size
    # https://chat.lgk.one/bitzlato/pl/e4ixc1wyxpy13d84tezdcbfy4a
    address =~ /^[a-z][a-z0-9_]{1,27}$/i
  end

  def build_client; end
end
