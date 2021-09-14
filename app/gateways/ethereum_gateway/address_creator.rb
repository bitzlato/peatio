class EthereumGateway
  class AddressCreator < AbstractCommand
    def call(secret = nil)
      secret ||= PasswordGenerator.generate
      {
        address: normalize_address(client.json_rpc(:personal_newAccount, [secret])),
        secret: secret
      }
    rescue Ethereum::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end
  end
end
