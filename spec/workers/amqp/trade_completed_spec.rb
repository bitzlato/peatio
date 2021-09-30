# frozen_string_literal: true

describe Workers::AMQP::TradeCompleted do
  subject { described_class.new }

  let(:order_ask) { create(:order_ask, :btc_usd) }
  let(:order_bid) { create(:order_bid, :btc_usd) }
  let(:trade) { create(:trade, :btc_usd, maker_order: order_ask, taker_order: order_bid) }
  let(:member) { trade.maker }

  describe '#generate_message' do
    let(:payload) { Hashie::Mash.new trade.send(:for_notify, member).merge(member_uid: member.uid) }

    it do
      expect(
        subject.send(:generate_message, member, payload)
      ).to include 'совершил сделку'
    end
  end
end
