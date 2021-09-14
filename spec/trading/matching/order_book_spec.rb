# frozen_string_literal: true

describe Matching::OrderBook do
  describe '#find' do
    subject { Matching::OrderBook.new('btc_usd', :ask) }

    it 'finds specific order' do
      o1 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      subject.add o1
      subject.add o2

      expect(subject.find(o1.dup).object_id).to eq o1.object_id
      expect(subject.find(o2.dup).object_id).to eq o2.object_id
    end
  end

  describe '#add' do
    subject { Matching::OrderBook.new('btc_usd', :ask) }

    it 'rejects invalid order whose volume is zero' do
      expect do
        subject.add Matching.mock_limit_order(type: :ask, volume: '0.0'.to_d)
      end.to raise_error(Matching::OrderError)
    end

    it 'adds market order' do
      subject.add Matching.mock_limit_order(type: :ask)

      o1 = Matching.mock_market_order(type: :ask)
      expect { subject.add o1 }.to raise_error(Matching::MarketOrderbookError)
    end

    it 'creates price level for order with new price' do
      order = Matching.mock_limit_order(type: :ask)
      subject.add order
      expect(subject.limit_orders.keys.first).to eq order.price
      expect(subject.limit_orders.values.first).to eq [order]
    end

    it 'adds order with same price to same price level' do
      o1 = Matching.mock_limit_order(type: :ask)
      o2 = Matching.mock_limit_order(type: :ask, price: o1.price)
      subject.add o1
      subject.add o2

      expect(subject.limit_orders.keys.size).to eq 1
      expect(subject.limit_orders.values.first).to eq [o1, o2]
    end

    it 'does not broadcast add event' do
      order = Matching.mock_limit_order(type: :ask)

      AMQP::Queue.expects(:enqueue).with(:slave_book, { action: 'add', order: order.attributes }, persistent: false).never
      Matching::OrderBook.new('btc_usd', :ask, broadcast: false).add order
    end
  end

  describe '#remove' do
    subject { Matching::OrderBook.new('btc_usd', :ask) }

    it 'removes market order' do
      subject.define_singleton_method(:legacy_add) do |order|
        raise Matching::InvalidOrderError, 'volume is zero' if order.volume <= 0.to_d

        case order
        when Matching::LimitOrder
          @limit_orders[order.price] ||= PriceLevel.new(order.price)
          @limit_orders[order.price].add order
        when Matching::MarketOrder
          @market_orders[order.id] = order
        else
          raise ArgumentError, 'Unknown order type'
        end
      end

      subject.add Matching.mock_limit_order(type: :ask)
      order = Matching.mock_market_order(type: :ask)
      subject.legacy_add order
      subject.remove order
      expect(subject.market_orders).to be_empty
    end

    it 'removes limit order' do
      o1 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      subject.add o1
      subject.add o2
      subject.remove o1.dup # dup so it's not the same object, but has same id

      expect(subject.limit_orders.values.first.size).to eq 1
    end

    it 'removes price level if its only limit order removed' do
      order = Matching.mock_limit_order(type: :ask)
      subject.add order
      subject.remove order.dup
      expect(subject.limit_orders).to be_empty
    end

    it 'returns nil if order is not found' do
      order = Matching.mock_limit_order(type: :ask)
      expect(subject.remove(order)).to be_nil
    end

    it 'returns order in book' do
      o1 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2 = o1.dup
      o1.instance_variable_set(:@volume, '12345'.to_d)
      subject.add o1
      o = subject.remove o2
      expect(o.volume).to eq '12345'.to_d
    end
  end

  describe '#best_limit_price' do
    it 'returns highest bid price' do
      book = Matching::OrderBook.new('btc_usd', :bid)
      o1   = Matching.mock_limit_order(type: :bid, price: '1.0'.to_d)
      o2   = Matching.mock_limit_order(type: :bid, price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.best_limit_price).to eq o2.price
    end

    it 'returns lowest ask price' do
      book = Matching::OrderBook.new('btc_usd', :ask)
      o1   = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2   = Matching.mock_limit_order(type: :ask, price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.best_limit_price).to eq o1.price
    end

    it 'returns nil if there`s no limit order' do
      book = Matching::OrderBook.new('btc_usd', :ask)
      expect(book.best_limit_price).to be_nil
    end
  end

  describe '#top' do
    it 'returns nil for empty book' do
      book = Matching::OrderBook.new('btc_usd', :ask)
      expect(book.top).to be_nil
    end

    it 'finds ask order with lowest price' do
      book = Matching::OrderBook.new('btc_usd', :ask)
      o1 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2 = Matching.mock_limit_order(type: :ask, price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.top).to eq o1
    end

    it 'finds bid order with highest price' do
      book = Matching::OrderBook.new('btc_usd', :bid)
      o1 = Matching.mock_limit_order(type: :bid, price: '1.0'.to_d)
      o2 = Matching.mock_limit_order(type: :bid, price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.top).to eq o2
    end

    it 'favors earlier order if orders have same price' do
      book = Matching::OrderBook.new('btc_usd', :ask)
      o1 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      book.add o1
      book.add o2

      expect(book.top).to eq o1
    end
  end

  describe '#fill_top' do
    subject { Matching::OrderBook.new('btc_usd', :ask) }

    it 'raises error if there is no top order' do
      expect do
        subject.fill_top('1.0'.to_d, '1.0'.to_d, '1.0'.to_d)
      end.to raise_error(RuntimeError, 'No top order in empty book.')
    end

    it 'removes the price level if top order is the only order in level' do
      subject.add Matching.mock_limit_order(type: :ask, volume: '1.0'.to_d)
      subject.fill_top '1.0'.to_d, '1.0'.to_d, '1.0'.to_d
      expect(subject.limit_orders).to be_empty
    end

    it 'removes order from level' do
      subject.add Matching.mock_limit_order(type: :ask, volume: '1.0'.to_d)
      subject.add Matching.mock_limit_order(type: :ask, volume: '1.0'.to_d)
      subject.fill_top '1.0'.to_d, '1.0'.to_d, '1.0'.to_d
      expect(subject.limit_orders.values.first.size).to eq 1
    end

    it 'fills top order with volume' do
      subject.add Matching.mock_limit_order(type: :ask, volume: '2.0'.to_d)
      subject.fill_top '1.0'.to_d, '0.5'.to_d, '0.5'.to_d
      expect(subject.top.volume).to eq '1.5'.to_d
    end
  end

  context 'on_change callback provided' do
    subject { Matching::OrderBook.new('btc_usd', :ask, on_change: callback) }

    let(:callback) { Object.new }

    it 'notifies add limit order' do
      order = Matching.mock_limit_order(type: :ask)
      callback.expects(:call).with('btc_usd', :ask, order.price, order.volume)
      subject.add order
    end

    it 'notifies remove limit order' do
      o1 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)
      o2 = Matching.mock_limit_order(type: :ask, price: '1.0'.to_d)

      callback.expects(:call).with('btc_usd', :ask, '1.0'.to_d, o1.volume)
      callback.expects(:call).with('btc_usd', :ask, '1.0'.to_d, o2.volume + o1.volume)
      callback.expects(:call).with('btc_usd', :ask, '1.0'.to_d, o2.volume)

      subject.add o1
      subject.add o2
      subject.remove o1.dup # dup so it's not the same object, but has same id

      expect(subject.limit_orders.values.first.size).to eq 1
    end

    it 'notifies fill top order with volume' do
      o1 = Matching.mock_limit_order(type: :ask, volume: '2.0'.to_d)
      callback.expects(:call).with('btc_usd', :ask, o1.price, '2.0'.to_d)
      callback.expects(:call).with('btc_usd', :ask, o1.price, '1.5'.to_d)
      subject.add(o1)
      subject.fill_top(o1.price, '0.5'.to_d, '0.5'.to_d)
    end
  end
end
