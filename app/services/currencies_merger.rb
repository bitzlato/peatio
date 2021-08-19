class CurrenciesMerger
  def call(from_currency, to_currency)
    AccountsMerger.new.call(from_currency, to_currency)
    fc = Currency.find(from_currency)
    fc.update visible: false, deposit_enabled: false, withdrawal_enabled: false
    tc = Currency.find(to_currency)
    tc.update visible: false, deposit_enabled: false, withdrawal_enabled: false

    Account.transaction do
      Account.lock do
        raise 'has balanced accounts' if Account.where(currency_id: from_currency).where('balance > 0 or locked >0').any?
        Account.where(currency_id: from_currency).delete_all

        Market.where(base_unit: from_currency).update_all base_unit: to_currency
        Market.where(quote_unit: from_currency).update_all quote_unit: to_currency
      end

      CurrencyWallet.where(currency_id: from_currency).delete_all

      [
        Adjustment,
        Operations::Asset,
        Operations::Expense,
        Operations::Liability,
        Operations::Revenue,
        Beneficiary,
        DepositSpread,
        Deposit,
        Withdraw
      ].each do |model|
        model.where(currency_id: from_currency).update_all currency_id: to_currency
      end
    end
  end
end
