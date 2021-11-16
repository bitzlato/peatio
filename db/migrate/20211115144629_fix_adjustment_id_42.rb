# frozen_string_literal: true

class FixAdjustmentId42 < ActiveRecord::Migration[5.2]
  def change
    return unless Rails.env.production?

    member = Member.find_by(uid: 'ID2C4D9F6CA3')
    currency = Currency.find_by(id: :btc)

    deposit = Deposit.create!(
      type: Deposit.name,
      member: member,
      currency: currency,
      amount: 0.016
    )
    deposit.accept!
    deposit.dispatch!
  end
end
