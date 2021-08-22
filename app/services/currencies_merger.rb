class CurrenciesMerger
  def call(from_currency, to_currency)
    fc = Currency.find(from_currency)
    fc.update visible: false, deposit_enabled: false, withdrawal_enabled: false
    tc = Currency.find(to_currency)
    tc.update visible: false, deposit_enabled: false, withdrawal_enabled: false

    Order.where(market: Market.where(quote_unit: from_currency)).active.pluck(:id).each do |id|
      Order.cancel id
    end
    Order.where(market: Market.where(base_unit: from_currency)).active.pluck(:id).each do |id|
      Order.cancel id
    end
    Withdraw.where(currency_id: from_currency, aasm_state: :accepted).find_each &:cancel!
    AccountsMerger.new.call(from_currency, to_currency)
    Market.where(base_unit: from_currency).update_all base_unit: to_currency
    Market.where(quote_unit: from_currency).update_all quote_unit: to_currency

    # Don't delete now
    # CurrencyWallet.where(currency_id: from_currency).delete_all

    [
      Adjustment,
      Operations::Asset,
      Operations::Expense,
      Operations::Liability,
      Operations::Revenue,
      Beneficiary,
      DepositSpread,
      Deposit,
      Transaction,
      Withdraw
    ].each do |model|
      puts "Move #{model} from #{from_currency} to #{to_currency}"
      model.where(currency_id: from_currency).update_all currency_id: to_currency
    end
  end
end
