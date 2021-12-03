# frozen_string_literal: true

describe Workers::Daemons::StaleOrderCancellator do
  it 'publishes cancel action to matching queue' do
    order = create(:order_ask, :btc_eth, state: :wait, canceling_at: 2.minutes.ago)
    AMQP::Queue.expects(:enqueue).with(:matching, { action: 'cancel', order: order.to_matching_attributes })
    described_class.new.process
  end
end
