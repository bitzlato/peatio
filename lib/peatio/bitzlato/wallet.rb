require 'digest'

module Bitzlato
  class Wallet < Peatio::Wallet::Abstract
    class WithdrawInfo
      attr_accessor :is_done, :withdraw_id, :currency, :amount
    end

    WITHDRAW_METHODS = %w[payment voucher]
    WITHDRAW_METHOD = ENV.fetch('BITZLATO_WITHDRAW_METHOD', WITHDRAW_METHODS.first)

    def initialize(features = {})
      @features = features
      @settings = {}
    end

    def configure(settings = {})
      # Clean client state during configure.
      @client = nil
      @settings = settings
    end

    def create_transaction!(transaction, options = {})
      case WITHDRAW_METHOD
      when 'voucher'
        create_voucher! transaction, options
      when 'payment'
        create_payment! transaction, options
      else
        raise Peatio::Wallet::ClientError, "Unknown withdraw_polling_method specified (#{WITHDRAW_METHOD})"
      end
    end

    def create_payment!(transaction, options = {})
      key = transaction.options[:withdrawal_id] || raise("No withdrawal ID")
      response = client.post(
        '/api/gate/v1/payments/create',
        { clientProvidedId: key, client: transaction.to_address, cryptocurrency: transaction.currency_code.upcase, amount: transaction.amount, payedBefore: true }
      )
      payment_id = response['paymentId'] || raise("No payment ID in response")
      transaction.hash = transaction.txout = generate_id payment_id
      transaction.options.merge! payment_id: payment_id
      transaction.status = 'succeed'
      transaction
    rescue Bitzlato::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    def create_voucher!(transaction, options = {})
      voucher = client.post(
        '/api/p2p/vouchers/',
        { cryptocurrency: transaction.currency_code.upcase, amount: transaction.amount, method: 'crypto', currency: 'USD'}
      )

      transaction.options.merge!(
        'voucher' => voucher,
        'links' => voucher['links'].map { |link| { 'title' => link['type'], 'url' => link['url'] } }
      )

      transaction.txout = voucher['deepLinkCode']
      transaction.hash = voucher['deepLinkCode']
      transaction
    rescue Bitzlato::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    def load_balance!
      response = client
        .get('/api/p2p/wallets/v2/')

      # [
        #{
          #"cryptocurrency": "BTC",
          #"balance": "0.03844557",
          #"holdBalance": "0",
          #"address": null,
          #"createdAt": 1622456228000,
          #"worth": {
            #"currency": "USD",
            #"value": "1324",
            #"holdValue": "0"
          #}
        #},
      response
        .find { |r| r['cryptocurrency'] == currency_code.upcase }
        .fetch('balance')
        .to_d
    end

    def create_invoice!(amount: , comment:)
      response = client
        .post('/api/gate/v1/invoices/', {
        cryptocurrency: currency_code.to_s.upcase,
        amount: amount,
        comment: comment
        })

      {
        amount: response['amount'].to_d,
        username: response['username'],
        id: generate_id(response['id']),
        links: response['link'].each_with_object([]) { |e, a| a << { 'title' => e.first, 'url' => e.second } },
        expires_at: Time.at(response['expiryAt']/1000)
      }
    end

    def poll_deposits
      client
        .get('/api/gate/v1/invoices/transactions/')['data']
        .map do |transaction|
        {
          address: transaction['username'],
          id: generate_id(transaction['invoiceId']),
          amount: transaction['amount'].to_d,
          currency: transaction['cryptocurrency'].downcase
        }
      end
    end

    def poll_withdraws
      withdraw_polling_methods.map do |method|
        case method
        when 'voucher'
          poll_vouchers
        when 'payment'
          poll_payments
        else
          report_exception(
            Peatio::Wallet::MissingSettingError.new(
              "Unknwo bitzlato withdraw polling method #{method}"
            )
          )
          []
        end
      end.flatten
    end

    private

    def withdraw_polling_methods
      ENV.fetch('BITZLATO_WITHDRAW_POLLING_METHODS', WITHDRAW_METHOD).split(',')
    end

    def poll_payments
      client
        .get('/api/gate/v1/payments/list/')
        .map do |payment|
        WithdrawInfo.new.tap do |w|
          w.withdraw_id = payment['clientProvidedId']
          w.is_done = payment['status'] == 'done'
          w.amount = payment['amount'].to_d
          w.currency = payment['cryptocurrency']
        end
      end
    end

    def poll_vouchers
      client
        .get('/api/p2p/vouchers/')['data']
        .map do |voucher|
        WithdrawInfo.new.tap do |w|
          w.withdraw_id = voucher['deepLinkCode']
          w.is_done = voucher['status'] == 'cashed'
          w.amount = voucher.dig('cryptocurrency', 'amount').to_d
          w.currency = voucher.dig('cryptocurrency', 'code').downcase
        end
      end
    end

    def currency
      @settings.fetch(:currency) do
       raise Peatio::Wallet::MissingSettingError, :currency
      end.slice(:id)
    end

    def currency_code
      currency.fetch(:code)
    end

    def generate_id id
      [client.uid, id] * ':'
    end

    def client
      @client ||= Bitzlato::Client
        .new(home_url: ENV.fetch('BITZLATO_API_URL'),
             key: ENV.fetch('BITZLATO_API_KEY').yield_self { |key| key.is_a?(String) ? JSON.parse(key) : key }.transform_keys(&:to_sym),
             uid: ENV.fetch('BITZLATO_API_CLIENT_UID').to_i,
             logger: ENV.true?('BITZLATO_API_LOGGER'))
    end
  end
end
