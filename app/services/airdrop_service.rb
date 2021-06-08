# Make an incentive airdrop deposit
#
class AirdropService
  def airdrop_for(user:, currency:, amount:)
    Deposit.
    Adjustment.create!(
      state: :accepted,
      currency: currency,
      creator: creator
      category: 'incentive'
      reason: 'auto incentive'

    )
  end
end
