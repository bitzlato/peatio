# frozen_string_literal: true

describe SwapOrder, type: :model do
  let(:member) { create :member }

  describe '.daily_unified_total_amount_for' do
    it 'return total daily amount' do
      create :swap_order_bid, :btc_usd, request_volume: 1, member: member, created_at: DateTime.yesterday
      create :swap_order_bid, :btc_usd, request_volume: 1, member: member, state: 'cancel'
      create_list :swap_order_bid, 2, :btc_usd, request_volume: 1, member: member
      expect(described_class.daily_amount_for(member)).to eq(2)
    end
  end

  describe '.weekly_unified_total_amount_for' do
    it 'return total weekly amount' do
      create :swap_order_bid, :btc_usd, request_volume: 1, created_at: DateTime.current.weeks_ago(1)
      create :swap_order_bid, :btc_usd, request_volume: 1, member: member, state: 'cancel'
      create_list :swap_order_bid, 2, :btc_usd, request_volume: 1, member: member
      expect(described_class.weekly_amount_for(member)).to eq(2)
    end
  end
end
