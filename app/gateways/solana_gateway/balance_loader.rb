# frozen_string_literal: true

class SolanaGateway
  class BalanceLoader < Base
    def load_balances(address)
      blockchain.currencies.each_with_object({}) do |currency, a|
        a[currency.id] = load_balance(address, currency)
      end
    end

    def load_balance(address, currency)
      currency = currency.currency_record if currency.is_a? Money::Currency
      blockchain_currency = BlockchainCurrency.find_by!(blockchain: blockchain, currency: currency)
      load_api_data(address, blockchain_currency).yield_self{|amount| blockchain_currency.to_money_from_units(amount) }
    end

    private

    def load_api_data address, blockchain_currency
      if blockchain_currency.contract_address.present?
        load_erc20_balance(address, blockchain_currency)
      else
        api.get_balance(address)
      end
    end

    def load_erc20_balance(address, blockchain_currency)
      if load_token_balance?(address, blockchain_currency)
        result = api.get_token_account_balance(address)
        result['value']['amount'].to_i
      else
        0
      end
    end

    def load_token_balance? address, blockchain_currency
      # load token balance only for payment_address specified for that token
      pa_conditions = { address: address, blockchain_currency: blockchain_currency }
      payment_address = blockchain.payment_addresses.where(pa_conditions).first
      return true if payment_address.present?

      # load token balance only for wallet supporting that token
      wallet = blockchain.wallets.where(address: address).with_currency(blockchain_currency.currency).first
      wallet.present?
    end
  end
end
