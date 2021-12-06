# frozen_string_literal: true

describe Workers::Daemons::SwapOrderStatusChecker do
  let(:swap_order) { create :swap_order_bid, :btc_usd }
  let(:order) { swap_order.order }

  it do
    order.update! state: Order::DONE

    expect do
      described_class.new.process
    end.to change { swap_order.reload.state }.to('done')
  end
end
