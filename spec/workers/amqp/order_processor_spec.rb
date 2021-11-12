# frozen_string_literal: true

describe Workers::AMQP::OrderProcessor do
  subject(:processor) { described_class.new }

  describe '#submit_order' do
    let(:order)          { create(:order_bid, :with_deposit_liability, state: 'pending', price: '12.32'.to_d, volume: '123.12345678') }
    let(:rejected_order) { create(:order_bid, :with_deposit_liability, state: 'reject', price: '12.32'.to_d, volume: '123.12345678') }
    let(:order_bid)      { create(:order_bid, :with_deposit_liability, state: 'pending', price: '12.32'.to_d, volume: '123.12345678') }
    let(:order_ask)      { create(:order_ask, :with_deposit_liability, state: 'pending', price: '12.32'.to_d, volume: '123.12345678') }

    before do
      processor.send :submit_order, order_bid.id
      processor.send :submit_order, order_ask.id
    end

    it do
      expect(order_bid.reload.state).to eq 'wait'
      expect(Operations::Liability.where(reference: order_ask).count).to eq 2
      expect(Operations::Liability.where(reference: order_bid).count).to eq 2
    end

    context 'validations' do
      before do
        order.member.accounts.find_by_currency_id(order.currency).update(balance: 0)
      end

      it 'insufficient balance' do
        expect do
          processor.send :submit_order, order.id
        end.to raise_error(Account::AccountError)
        expect(order.reload.state).to eq('reject')
      end

      it 'rejected order' do
        processor.send :submit_order, rejected_order.id
        expect(rejected_order.reload.state).to eq('reject')
      end
    end

    if defined? Mysql2
      it 'mysql connection error' do
        ActiveRecord::Base.stubs(:transaction).raises(Mysql2::Error::ConnectionError.new(''))
        expect { processor.send :submit_order, order.id }.to raise_error(Mysql2::Error::ConnectionError)
      end
    end

    if defined? PG
      it 'postgresql connection error' do
        ActiveRecord::Base.stubs(:transaction).raises(PG::Error.new(''))
        expect { processor.send :cancel_order, order.id }.to raise_error(PG::Error)
      end
    end
  end

  describe '#cancel_order' do
    let(:order) { create(:order_bid, :with_deposit_liability, state: 'pending', price: '12.32'.to_d, volume: '123.12345678') }

    if defined? Mysql2
      it 'mysql connection error' do
        ActiveRecord::Base.stubs(:transaction).raises(Mysql2::Error::ConnectionError.new(''))
        expect { processor.send :cancel_order, order.id }.to raise_error(Mysql2::Error::ConnectionError)
      end
    end

    if defined? PG
      it 'postgresql connection error' do
        ActiveRecord::Base.stubs(:transaction).raises(PG::Error.new(''))
        expect { processor.send :cancel_order, order.id }.to raise_error(PG::Error)
      end
    end
  end

  describe '#process' do
    let(:member) { create(:member, :level_3) }
    let(:order) { create(:order_bid, :btc_usd, price: '12.32'.to_d, volume: '3.14', origin_volume: '12.13', locked: '20.1082', origin_locked: '38.0882', member: member) }

    context 'when action is cancel_matching' do
      it do
        AMQP::Queue.expects(:enqueue).with(:matching, action: 'cancel', order: order.to_matching_attributes)
        AMQP::Queue.expects(:publish).with(order.market.engine.driver, data: order.as_json_for_third_party, type: 3).never
        processor.process('action' => 'cancel_matching', 'order' => { 'id' => order.id })
      end
    end

    context 'when action is cancel_matching for third party order' do
      it do
        order.market.engine.update(driver: 'finex-spot')
        AMQP::Queue.expects(:enqueue).with(:matching, action: 'cancel', order: order.to_matching_attributes).never
        AMQP::Queue.expects(:publish).with(order.market.engine.driver, data: order.as_json_for_third_party, type: 3)
        processor.process('action' => 'cancel_matching', 'order' => { 'id' => order.id })
      end
    end
  end
end
