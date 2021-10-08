# frozen_string_literal: true

class BalancesUpdater
  def initialize(blockchain:, address:)
    @blockchain = blockchain
    @address = address
  end

  def perform
    return unless @blockchain.active?

    payment_address = PaymentAddress.find_by(blockchain: @blockchain, address: @address)
    wallet = Wallet.find_by(blockchain: @blockchain, address: @address)
    if payment_address.present?
      if @blockchain.gateway_class.enable_personal_address_balance?
        Rails.logger.debug { "Update payment address balances for #{@address}" }
        balances = convert_balances(@blockchain.gateway.load_balances(@address))
      else
        balances = {}
      end
      payment_address.update!({ balances: balances, balances_updated_at: Time.zone.now })
    elsif wallet.present?
      balances = convert_balances(current_balances(wallet))
      wallet.update!({ balance: balances, balance_updated_at: Time.zone.now })
    else
      raise e if Rails.env.test?
    end
  rescue StandardError => e
    raise e if Rails.env.test?
    Rails.logger.warn(message: 'Balances updating error', error: e, payment_address_id: payment_address&.id, wallet_id: wallet&.id)
    report_exception e, true, payment_address_id: payment_address&.id, wallet_id: wallet&.id
  end

  private

  def convert_balances(balances)
    b = balances.each_with_object({}) do |(k, v), a|
      currency_id = k.is_a?(Money::Currency) || k.is_a?(Currency) ? k.id.downcase : k
      a[currency_id] = v.to_d
    end
    b.select { |_k, v| v.positive? }
  end

  def current_balances(wallet)
    if @blockchain.gateway.is_a? BitzlatoGateway
      @blockchain.gateway.load_balances
    else
      wallet.currencies.each_with_object({}) do |c, balances|
        balances[c.id] = begin
          c = c.money_currency unless c.is_a? Money::Currency
          @blockchain.gateway.load_balance(wallet.address, c)
        rescue Peatio::Wallet::ClientError => e
          report_exception e, true, wallet_id: wallet.id
          nil
        end
      end
    end
  end
end
