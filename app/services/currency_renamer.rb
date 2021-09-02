class CurrencyRenamer
  # Example
  # CurrencyRenamer.new.call(:usdc, 'usdc-erc20')
  def call(old_id, new_id)
    Currency.find(old_id)
    Currency.where(id: old_id).update_all id: new_id

    Order.where(bid: old_id).update_all id: new_id
    Order.where(ask: old_id).update_all id: new_id

    Market.where(base_unit: old_id).update_all base_unit: new_id
    Market.where(quote_unit: old_id).update_all quote_unit: new_id

    Market.where('base_unit = ? or quote_unit = ?', new_id, new_id).each do |m|
      m.update_column :symbol, "#{m.base_currency}#{m.quote_currency}"
    end

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
      puts "Move #{model} from #{old_id} to #{new_id}"
      model.where(currency_id: old_id).update_all currency_id: new_id
    end
  end
end
