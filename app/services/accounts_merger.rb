class AccountsMerger
  def call(from_currency, to_currency)
    puts "Migrates accounts from #{from_currency} to #{to_currency}"
    Account.where(currency_id: from_currency).where('balance <> 0 and locked = 0').lock.each do |from_account|
      to_account = from_account.member.get_account(to_currency)
      amount = from_account.balance
      from_account.sub_funds amount
      to_account.plus_funds! amount

      puts "#{amount} #{from_currency} moved as #{to_currency} for #{from_account.member.uid}"
    end.count
  end
end
