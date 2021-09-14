# frozen_string_literal: true

describe Matching::Executor do
  subject do
    Matching::Executor.new(
      action: 'execute',
      trade: {
        market_id: market.symbol,
        maker_order_id: ask.id,
        taker_order_id: bid.id,
        strike_price: price.to_s('F'),
        amount: volume.to_s('F'),
        total: (price * volume).to_s('F')
      }
    )
  end

  let(:alice)  { who_is_billionaire }
  let(:bob)    { who_is_billionaire }
  let(:market) { Market.find_spot_by_symbol('btc_usd') }
  let(:price)  { 10.to_d }
  let(:volume) { 5.to_d }

  context 'invalid volume' do
    let(:ask) { ::Matching::LimitOrder.new create(:order_ask, :btc_usd, price: price, volume: volume, member: alice).to_matching_attributes }
    let(:bid) { ::Matching::LimitOrder.new create(:order_bid, :btc_usd, price: price, volume: 3.to_d, member: bob).to_matching_attributes }

    it 'raises error' do
      expect { subject.execute! }.to raise_error(Matching::TradeExecutionError)
    end
  end

  context 'invalid bid price' do
    let(:ask) { ::Matching::LimitOrder.new create(:order_ask, :btc_usd, price: price, volume: volume, member: alice).to_matching_attributes }
    let(:bid) { ::Matching::LimitOrder.new create(:order_bid, :btc_usd, price: price - 1, volume: volume, member: bob).to_matching_attributes }

    it 'raises error' do
      expect { subject.execute! }.to raise_error(Matching::TradeExecutionError)
    end
  end

  context 'invalid ask price' do
    let(:ask) { ::Matching::LimitOrder.new create(:order_ask, :btc_usd, price: price + 1, volume: volume, member: alice).to_matching_attributes }
    let(:bid) { ::Matching::LimitOrder.new create(:order_bid, :btc_usd, price: price, volume: volume, member: bob).to_matching_attributes }

    it 'raises error' do
      expect { subject.execute! }.to raise_error(Matching::TradeExecutionError)
    end
  end

  context 'full execution' do
    let(:ask) { ::Matching::LimitOrder.new create(:order_ask, :btc_usd, price: price, volume: volume, member: alice).to_matching_attributes }
    let(:bid) { ::Matching::LimitOrder.new create(:order_bid, :btc_usd, price: price, volume: volume, member: bob).to_matching_attributes }

    it 'creates trade' do
      expect do
        trade = subject.execute!

        expect(trade.price).to eq price
        expect(trade.amount).to eq volume
        expect(trade.maker_order_id).to eq ask.id
        expect(trade.taker_order_id).to eq bid.id
      end.to change(Trade, :count).by(1)
    end

    it 'sets trade used funds' do
      trade = subject.execute!
      expect(trade.total).to eq price * volume
    end

    it 'increases order\'s trades count' do
      subject.execute!
      expect(Order.find(ask.id).trades_count).to eq 1
      expect(Order.find(bid.id).trades_count).to eq 1
    end

    it 'marks both orders as done' do
      subject.execute!
      expect(Order.find(ask.id).state).to eq Order::DONE
      expect(Order.find(bid.id).state).to eq Order::DONE
    end

    it 'publishes trade through amqp' do
      AMQP::Queue.expects(:publish)
      subject.execute!
    end
  end

  context 'partial ask execution' do
    let(:ask) { create(:order_ask, :btc_usd, price: price, volume: 7.to_d, member: alice) }
    let(:bid) { create(:order_bid, :btc_usd, price: price, volume: 5.to_d, member: bob) }

    it 'sets bid to done only' do
      subject.execute!

      expect(ask.reload.state).not_to eq Order::DONE
      expect(bid.reload.state).to eq Order::DONE
    end
  end

  context 'partial bid execution' do
    let(:ask) { create(:order_ask, :btc_usd, price: price, volume: 5.to_d, member: alice) }
    let(:bid) { create(:order_bid, :btc_usd, price: price, volume: 7.to_d, member: bob) }

    it 'sets ask to done only' do
      subject.execute!

      expect(ask.reload.state).to eq Order::DONE
      expect(bid.reload.state).not_to eq Order::DONE
    end
  end

  context 'partially filled market order whose locked fund run out' do
    let(:ask) { create(:order_ask, :btc_usd, price: '2.0'.to_d, volume: '3.0'.to_d, member: alice) }
    let(:bid) { create(:order_bid, :btc_usd, price: nil, ord_type: 'market', volume: '2.0'.to_d, locked: '3.0'.to_d, member: bob) }

    it 'cancels the market order' do
      executor = Matching::Executor.new(
        action: 'execute',
        trade: {
          market_id: market.symbol,
          maker_order_id: ask.id,
          taker_order_id: bid.id,
          strike_price: '2.0'.to_d,
          amount: '1.5'.to_d,
          total: '3.0'.to_d
        }
      )
      executor.execute!

      expect(bid.reload.state).to eq Order::CANCEL
    end
  end

  context 'unlock not used funds' do
    subject do
      Matching::Executor.new(
        action: 'execute',
        trade: {
          market_id: market.symbol,
          maker_order_id: ask.id,
          taker_order_id: bid.id,
          strike_price: price - 1, # so bid order only used (price-1)*volume
          amount: volume.to_s('F'),
          total: ((price - 1) * volume).to_s('F')
        }
      )
    end

    let(:ask) { create(:order_ask, :btc_usd, price: price - 1, volume: 7.to_d, member: alice) }
    let(:bid) { create(:order_bid, :btc_usd, price: price, volume: volume, member: bob) }

    it 'unlocks funds not used by bid order' do
      locked_before = bid.hold_account.reload.locked

      subject.execute!
      locked_after = bid.hold_account.reload.locked

      expect(locked_after).to eq locked_before - (price * volume)
    end

    it 'saves unused amount in order locked attribute' do
      subject.execute!
      expect(bid.reload.locked).to eq (price * volume) - ((price - 1) * volume)
    end
  end

  context 'execution fail' do
    let(:ask) { ::Matching::LimitOrder.new create(:order_ask, :btc_usd, price: price, volume: volume, member: alice).to_matching_attributes }
    let(:bid) { ::Matching::LimitOrder.new create(:order_bid, :btc_usd, price: price, volume: volume, member: bob).to_matching_attributes }

    it 'does not create trade' do
      # set locked funds to 0 so strike will fail
      alice.get_account(:btc).update_attributes(locked: ::Trade::ZERO)

      expect do
        expect { subject.execute! }.to raise_error(Account::AccountError)
      end.not_to change(Trade, :count)
    end
  end
end
