# frozen_string_literal: true

class AccountsMerger
  def call(from_currency, to_currency)
    puts "Migrates accounts from #{from_currency} to #{to_currency}"
    Account.where(currency_id: from_currency).lock.each do |from_account|
      from_account.lock!
      to_account = from_account.member.get_account(to_currency)

      locked = from_account.locked
      from_account.unlock_funds! locked if locked.positive?

      balance = from_account.balance
      if balance.positive?
        from_account.sub_funds! balance
        to_account.plus_funds! balance
        puts "balance #{balance} #{from_currency} moved as #{to_currency} for #{from_account.member.uid}"
      end

      if locked.positive?
        to_account.lock_funds! locked
        puts "locked #{locked} #{from_currency} moved as #{to_currency} for #{from_account.member.uid}"
      end

      from_account.delete
    end.count
    raise 'has balanced accounts' if Account.where(currency_id: from_currency).any?
  end
end
