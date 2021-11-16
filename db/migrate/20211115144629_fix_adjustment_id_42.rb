# frozen_string_literal: true

class FixAdjustmentId42 < ActiveRecord::Migration[5.2]
  def change
    return unless Rails.env.production?

    member = Member.find_by(uid: 'ID505131DE7B') # bitzlato:Jayjay
    currency = Currency.find_by(id: :btc)

    deposit = Deposit.create!(
      type: Deposit.name,
      member: member,
      currency: currency,
      amount: 0.008,
      invoice_id: '14222639:30969-2'
    )
    deposit.accept!
    deposit.dispatch!

    deposit = Deposit.create!(
      type: Deposit.name,
      member: member,
      currency: currency,
      amount: 0.008,
      invoice_id: '14222639:30969-3'
    )
    deposit.accept!
    deposit.dispatch!
  end
end
