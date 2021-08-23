module PaymentAddressTotals
  def total_balances
    connection
      .execute('SELECT "key", sum("val"::decimal) FROM payment_addresses, LATERAL jsonb_each_text(balances) AS each(KEY,val) GROUP BY "key"')
      .each_with_object({}) { |r, a| a[r['key'].downcase] = r['sum'] }
  end

  def total_currencies
    group(:currency_id).pluck('jsonb_object_keys(balances) as currency_id')
  end

  def total_balance(currency_id)
    select("sum((balances ->> '#{currency_id.downcase}') :: decimal) as balance").take.attributes['balance']
  end
end
