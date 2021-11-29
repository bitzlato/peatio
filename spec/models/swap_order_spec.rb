# frozen_string_literal: true

describe SwapOrder, type: :model do
  let(:member) { create :member }

  describe '.daily_unified_total_amount_for' do
    it 'return total daily amount' do
      create :swap_order_bid, :btc_usd, member: member, unified_price: 100, created_at: DateTime.yesterday
      create :swap_order_bid, :btc_usd, member: member, unified_price: 100, state: 'cancel'
      create_list :swap_order_bid, 2, :btc_usd, member: member, unified_total_amount: 100
      expect(described_class.daily_unified_total_amount_for(member)).to eq(200)
    end
  end

  describe '.weekly_unified_total_amount_for' do
    it 'return total weekly amount' do
      create :swap_order_bid, :btc_usd, unified_price: 100, created_at: DateTime.current.weeks_ago(1)
      create :swap_order_bid, :btc_usd, member: member, unified_price: 100, state: 'cancel'
      create_list :swap_order_bid, 2, :btc_usd, member: member, unified_total_amount: 100
      expect(described_class.weekly_unified_total_amount_for(member)).to eq(200)
    end
  end
end
