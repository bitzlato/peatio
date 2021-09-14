# frozen_string_literal: true

describe Workers::AMQP::CancelMemberOrders do
  let!(:member) { create(:member, :level_3) }
  let!(:account) do
    create(:account, :usd, balance: 100.to_d, locked: 2.to_d, member: member)
  end
  let!(:account1) do
    create(:account, :btc, balance: 100.to_d, locked: 2.to_d, member: member)
  end

  let!(:ask_orders) do
    create(
      :order_ask, :btc_usd,
      price: '1', volume: '1.0', state: :wait,
      member: member
    )
    create(
      :order_ask, :btc_usd,
      price: '1', volume: '1.0', state: :wait,
      member: member
    )
  end
  let!(:bid_orders) do
    create(
      :order_bid, :btc_usd,
      price: '1', volume: '1.0', state: :wait,
      member: member
    )
    create(
      :order_bid, :btc_usd,
      price: '1', volume: '1.0', state: :wait,
      member: member
    )
  end

  subject { Workers::AMQP::CancelMemberOrders.new }

  describe '#perform' do
    it 'cancels all active member orders' do
      expect do
        subject.process({
                          event: 'close_all_orders',
                          member_uid: member.uid
                        })
      end.to change { member.orders.active.count }.from(4).to(0)
    end
  end
end
