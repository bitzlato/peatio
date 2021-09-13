# encoding: UTF-8
# frozen_string_literal: true

namespace :accounts do
  desc 'Create missing accounts for existing members.'
  task touch: :environment do
    Member.find_each(&:touch_accounts)
  end

  desc 'Merge accounts by currencies'
  task :merge, [:from_currency, :to_currency] => [:environment] do |_, args|
    from_currency = (args[:from_currency] || raise('no from_currency')).downcase
    to_currency = (args[:to_currency] || raise('no to_currency')).downcase

    AccountsMerger.new.call(from_currency, to_currency)
  end

  desc 'Mark deposits and withdraws of accounts as locked'
  task lock_deposits_and_withdraws: :environment do
    Account.where.not(locked: 0).find_each do |account|
      account.deposits.accepted.joins(:currency).merge(Currency.coins).update_all(is_locked: true)
      account.withdraws.where.not(aasm_state: %i[prepared canceled rejected succeed failed]).update_all(is_locked: true)
    end
  end
end
