# frozen_string_literal: true

class BalancesUpdater
  def initialize(blockchain:, address:)
    @blockchain = blockchain || raise('No blockchain')
    @address = address || raise('No address')
  end

  def perform
    return unless @blockchain.active?

    payment_address = PaymentAddress.find_by(blockchain: @blockchain, address: @address)
    return update_payment_address payment_address if payment_address.present?

    wallet = Wallet.find_by(blockchain: @blockchain, address: @address)
    return update_wallet wallet if wallet.present?

    Rails.logger.warn("No found wallet or payment_address with address #{@address}")
  rescue StandardError => e
    Rails.logger.warn(message: 'Balances updating error', error: e, payment_address_id: payment_address&.id, wallet_id: wallet&.id)
    report_exception e, true, payment_address_id: payment_address&.id, wallet_id: wallet&.id
  end

  private

  def update_wallet(wallet)
    balances = convert_balances(current_balances(wallet))
    wallet.update!({ balance: balances, balance_updated_at: Time.zone.now })
    balances
  end

  def update_payment_address(payment_address)
    if @blockchain.gateway_class.enable_personal_address_balance?
      Rails.logger.debug { "Update payment address balances for #{@address}" }
      balances = convert_balances(@blockchain.gateway.load_balances(@address))
    else
      Rails.logger.warn "Disabled personal address balance for #{@blockchain}"
      balances = {}
    end
    payment_address.update!({ balances: balances, balances_updated_at: Time.zone.now })
    balances
  end

  def convert_balances(balances)
    b = balances.each_with_object({}) do |(k, v), a|
      currency_id = k.is_a?(Money::Currency) || k.is_a?(Currency) ? k.id.downcase : k
      a[currency_id] = v.to_d
    end
    b.select { |_k, v| v.positive? }
  end

  def current_balances(wallet)
    return {} if @blockchain.gateway.is_a? BitzlatoGateway

    wallet.currencies.each_with_object({}) do |c, balances|
      balances[c.id] = begin
        blockchain_currency = BlockchainCurrency.find_by!(blockchain: @blockchain, currency: c)
        c = blockchain_currency.money_currency
        @blockchain.gateway.load_balance(wallet.address, c)
      rescue Peatio::Wallet::ClientError => e
        report_exception e, true, wallet_id: wallet.id
        nil
      end
    end
  end
end
