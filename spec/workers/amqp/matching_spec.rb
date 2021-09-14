# frozen_string_literal: true

describe Workers::AMQP::Matching do
  subject { Workers::AMQP::Matching.new }

  let(:alice)  { who_is_billionaire }
  let(:bob)    { who_is_billionaire }
  let(:market) { Market.find_spot_by_symbol(:btc_usd) }

  context 'engines' do
    it 'gets all engines' do
      expect(subject.engines.keys.sort).to eq Market.spot.pluck(:symbol).sort
    end

    it 'starteds all engines' do
      expect(subject.engines.values.map(&:mode)).to eq Array.new(Market.spot.count, :run)
    end
  end

  context 'partial match' do
    let(:existing) { create(:order_ask, :btc_usd, price: '4001', volume: '10.0', member: alice) }

    before do
      subject.process({ action: 'submit', order: existing.to_matching_attributes }, {}, {})
    end

    it 'starteds engine' do
      expect(subject.engines['btc_usd'].mode).to eq :run
    end

    it 'matches part of existing order' do
      order = create(:order_bid, :btc_usd, price: '4001', volume: '8.0', member: bob)

      AMQP::Queue.expects(:enqueue)
                 .with(:trade_executor, { action: 'execute', trade: { market_id: market.symbol, maker_order_id: existing.id, taker_order_id: order.id, strike_price: '4001'.to_d, amount: '8.0'.to_d, total: '32008'.to_d } }, anything)
      subject.process({ action: 'submit', order: order.to_matching_attributes }, {}, {})
    end

    it 'matches part of new order' do
      order = create(:order_bid, :btc_usd, price: '4001', volume: '12.0', member: bob)

      AMQP::Queue.expects(:enqueue)
                 .with(:trade_executor, { action: 'execute', trade: { market_id: market.symbol, maker_order_id: existing.id, taker_order_id: order.id, strike_price: '4001'.to_d, amount: '10.0'.to_d, total: '40010'.to_d } }, anything)
      subject.process({ action: 'submit', order: order.to_matching_attributes }, {}, {})
    end
  end

  context 'complex partial match' do
    # submit  | ask price/volume | bid price/volume |
    # -----------------------------------------------
    # ask1    | 4003/3           |                  |
    # -----------------------------------------------
    # ask2    | 4002/3, 4003/3   |                  |
    # -----------------------------------------------
    # bid3    |                  | 4003/2           |
    # -----------------------------------------------
    # ask4    | 4002/3           |                  |
    # -----------------------------------------------
    # bid5    |                  |                  |
    # -----------------------------------------------
    # bid6    |                  | 4001/5           |
    # -----------------------------------------------
    let!(:ask1) { create(:order_ask, :btc_usd, price: '4003', volume: '3.0', member: alice) }
    let!(:ask2) { create(:order_ask, :btc_usd, price: '4002', volume: '3.0', member: alice) }
    let!(:bid3) { create(:order_bid, :btc_usd, price: '4003', volume: '8.0', member: bob) }
    let!(:ask4) { create(:order_ask, :btc_usd, price: '4002', volume: '5.0', member: alice) }
    let!(:bid5) { create(:order_bid, :btc_usd, price: '4003', volume: '3.0', member: bob) }
    let!(:bid6) { create(:order_bid, :btc_usd, price: '4001', volume: '5.0', member: bob) }

    let!(:orderbook) { Matching::OrderBookManager.new('btc_usd', broadcast: false) }
    let!(:engine)    { Matching::Engine.new(market, mode: :run) }

    before do
      engine.stubs(:orderbook).returns(orderbook)
      ::Matching::Engine.stubs(:new).returns(engine)
    end

    it 'creates many trades' do
      AMQP::Queue.expects(:enqueue)
                 .with(:trade_executor, { action: 'execute', trade: { market_id: market.symbol, maker_order_id: ask1.id, taker_order_id: bid3.id, strike_price: ask1.price, amount: ask1.volume, total: '12009'.to_d } }, anything).once
      AMQP::Queue.expects(:enqueue)
                 .with(:trade_executor, { action: 'execute', trade: { market_id: market.symbol, maker_order_id: ask2.id, taker_order_id: bid3.id, strike_price: ask2.price, amount: ask2.volume, total: '12006'.to_d } }, anything).once
      AMQP::Queue.expects(:enqueue)
                 .with(:trade_executor, { action: 'execute', trade: { market_id: market.symbol, taker_order_id: ask4.id, maker_order_id: bid3.id, strike_price: bid3.price, amount: '2.0'.to_d, total: '8006'.to_d } }, anything).once
      AMQP::Queue.expects(:enqueue)
                 .with(:trade_executor, { action: 'execute', trade: { market_id: market.symbol, maker_order_id: ask4.id, taker_order_id: bid5.id, strike_price: ask4.price, amount: bid5.volume, total: '12006'.to_d } }, anything).once

      subject
    end
  end

  context 'cancel order' do
    let(:existing) { create(:order_ask, :btc_usd, price: '4001', volume: '10.0', member: alice) }

    before do
      subject.process({ action: 'submit', order: existing.to_matching_attributes }, {}, {})
    end

    it 'cancels existing order' do
      subject.process({ action: 'cancel', order: existing.to_matching_attributes }, {}, {})
      expect(subject.engines[market.symbol].ask_orders.limit_orders).to be_empty
    end
  end

  context 'dryrun' do
    subject { Workers::AMQP::Matching.new(mode: :dryrun) }

    let!(:bid) { create(:order_bid, :btc_usd, price: '4001', volume: '8.0', member: bob) }

    context 'very old orders matched' do
      let!(:ask) { create(:order_ask, :btc_usd, price: '4000', volume: '3.0', member: alice, created_at: 1.day.ago) }

      it 'does not start engine' do
        expect(subject.engines['btc_usd'].mode).to eq :dryrun
        expect(subject.engines['btc_usd'].queue.size).to eq 1
      end
    end

    context 'buffered orders matched' do
      let!(:ask) { create(:order_ask, :btc_usd, price: '4000', volume: '3.0', member: alice) }

      it 'starts engine' do
        expect(subject.engines['btc_usd'].mode).to eq :run
      end
    end
  end
end
