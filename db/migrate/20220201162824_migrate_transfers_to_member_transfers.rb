# frozen_string_literal: true

class MigrateTransfersToMemberTransfers < ActiveRecord::Migration[5.2]
  def change
    Transfer.find_each do |transfer|
      raise 'wtf?' if transfer.liabilities.count != 1 || transfer.revenues.count != 1 || transfer.operations != 2

      liability = transfer.liabilities.first
      revenue = transfer.revenue.first

      mb = MemberTransfer.create!({
                                    id: transfer.id,
                                    key: transfer.key,
                                    currency: liability.currency,
                                    amount: liability.amount,
                                    memeber: liability.member,
                                    description: transfer.description,
                                    service: transfer.category,
                                    meta: transfer.attributes.merge(liability: liability.attributes, revenue: revenue.attributes),
                                    created_at: transfer.created_at,
                                    updated_at: transfer.updated_at
                                  })

      if mb.amount.positive?
        Operations::Asset.credit!(
          amount: mb.amount,
          currency: mb.currency,
          reference: mb
        )
        Operations::Liability.credit!(
          amount: mb.amount,
          currency: mb.currency,
          reference: mb,
          member_id: mb.member_id,
          kind: :main
        )
      else
        Operations::Asset.debit!(
          amount: -mb.amount,
          currency: mb.currency,
          reference: mb
        )
        Operations::Liability.debit!(
          amount: -mb.amount,
          currency: mb.currency,
          reference: mb,
          member_id: mb.member_id,
          kind: :main
        )
      end

      transfer.operations.each(&:destroy!)
    end
  end
end
