module Bitzlato
  class Wallet < Peatio::Wallet::Abstract
    def initialize(features = {})
      @features = features
      @settings = {}
    end

    def configure(settings = {})
      # Clean client state during configure.
      @client = nil

      @settings = settings

      @wallet = @settings.fetch(:wallet) do
        raise Peatio::Wallet::MissingSettingError, :wallet
      end.slice(:uri, :key, :uid)

      @currency = @settings.fetch(:currency) do
       raise Peatio::Wallet::MissingSettingError, :currency
      end.slice(:id)
    end

    def create_deposit_intention!(account_id: , amount: )
      response = client
        .post('/api/gate/v1/invoices/', {
        cryptocurrency: currency_id.to_s.upcase,
        amount: amount,
        comment: "Exchange service deposit for account #{account_id}"
        })

      {
        amount: response['amount'].to_d,
        username: response['username'],
        id: response['id'],
        links: response['link'].symbolize_keys,
        expires_at: Time.at(response['expiryAt']/1000)
      }
    end

    def poll_intentions
      client
        .get('/api/gate/v1/invoices/transactions/')['data']
        .map do |transaction|
        {
          id: transaction['invoiceId'],
          amount: transaction['amount'].to_d,
          cryptocurrency: transaction['cryptocurrency']
        }
      end
    end

    private

    def currency_id
      @currency.fetch(:id)
    end

    def client
      @client ||= Bitzlato::Client
        .new(home_url: @wallet.fetch(:uri),
             key: @wallet.fetch(:key),
             uid: @wallet.fetch(:uid),
             logger: Rails.env.development?)
    end
  end
end
