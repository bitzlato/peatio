# frozen_string_literal: true

describe TradingFee, 'Relationships' do
  context 'belongs to market' do
    context 'null market_id' do
      subject { build(:trading_fee) }

      it { expect(subject).to be_valid }
    end

    context 'existing market_id' do
      subject { build(:trading_fee, market_id: :btc_usd) }

      it { expect(subject).to be_valid }
    end

    context 'non-existing market_id' do
      subject { build(:trading_fee, market_id: :usdbtc) }

      it { expect(subject).not_to be_valid }
    end
  end
end

describe TradingFee, 'Validations' do
  before { TradingFee.delete_all }

  context 'market_type presence' do
    context 'nil market_type' do
      subject { build(:trading_fee, market_id: :btc_eth, market_type: '') }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'market_type inclusion' do
    context 'nil market_type' do
      subject { build(:trading_fee, market_id: :btc_eth, market_type: 'invalid') }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'group presence' do
    context 'nil group' do
      subject { build(:trading_fee, market_id: :btc_eth, group: nil) }

      it { expect(subject).not_to be_valid }
    end

    context 'empty string group' do
      subject { build(:trading_fee, market_id: :btc_eth, group: '') }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'group uniqueness' do
    context 'different markets' do
      before { create(:trading_fee, market_id: :btc_usd, group: 'vip-1') }

      context 'same group' do
        subject { build(:trading_fee, market_id: :btc_eth, group: 'vip-1') }

        it { expect(subject).to be_valid }
      end

      context 'different group' do
        subject { build(:trading_fee, market_id: :btc_eth, group: 'vip-2') }

        it { expect(subject).to be_valid }
      end

      context ':any group' do
        subject { build(:trading_fee, market_id: :btc_eth, group: :any) }

        before { create(:trading_fee, market_id: :btc_usd, group: :any) }

        it { expect(subject).to be_valid }
      end
    end

    context 'same market' do
      before { create(:trading_fee, market_id: :btc_usd, group: 'vip-1') }

      context 'same group' do
        subject { build(:trading_fee, market_id: :btc_usd, group: 'vip-1') }

        it { expect(subject).not_to be_valid }
      end

      context 'different group' do
        subject { build(:trading_fee, market_id: :btc_usd, group: 'vip-2') }

        it { expect(subject).to be_valid }
      end

      context ':any group' do
        subject { build(:trading_fee, market_id: :btc_usd, group: :any) }

        before { create(:trading_fee, market_id: :btc_usd, group: :any) }

        it { expect(subject).not_to be_valid }
      end
    end

    context ':any market' do
      before { create(:trading_fee, group: 'vip-1') }

      context 'same group' do
        subject { build(:trading_fee, group: 'vip-1') }

        it { expect(subject).not_to be_valid }
      end

      context 'different group' do
        subject { build(:trading_fee, group: 'vip-2') }

        it { expect(subject).to be_valid }
      end

      context ':any group' do
        subject { build(:trading_fee, group: :any) }

        before { create(:trading_fee, group: :any) }

        it { expect(subject).not_to be_valid }
      end
    end
  end

  context 'maker, taker numericality' do
    context 'non decimal maker/taker' do
      subject { build(:trading_fee, maker: '1', taker: '1') }

      it { expect(subject).not_to be_valid }
    end

    context 'valid trading_fee' do
      subject { build(:trading_fee, maker: 0.1, taker: 0.2) }

      it { expect(subject).to be_valid }
    end
  end

  context 'market_id presence' do
    context 'nil group' do
      subject { build(:trading_fee, market_id: nil) }

      it { expect(subject).not_to be_valid }
    end

    context 'empty string group' do
      subject { build(:trading_fee, market_id: '') }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'market_id inclusion in' do
    context 'invalid market_id' do
      subject { build(:trading_fee, market_id: :eth_usd) }

      it { expect(subject).not_to be_valid }
    end

    context 'valid trading_fee' do
      subject { build(:trading_fee, market_id: :btc_usd) }

      it { expect(subject).to be_valid }
    end
  end
end

describe TradingFee, 'Class Methods' do
  before { TradingFee.delete_all }

  describe '#for' do
    let!(:member) { create(:member) }

    context 'get trading_fee with marker_id and group' do
      subject { TradingFee.for(group: order.member.group, market_id: order.market_id) }

      before do
        create(:trading_fee, market_id: :btc_usd, group: 'vip-0')
        create(:trading_fee, market_id: :any, group: 'vip-0')
        create(:trading_fee, market_id: :btc_usd, group: :any)
        create(:trading_fee, market_id: :any, group: :any)
      end

      let(:order) { Order.new(member: member, market_id: :btc_usd) }

      it do
        expect(subject).to be_truthy
        expect(subject.market_id).to eq('btc_usd')
        expect(subject.group).to eq('vip-0')
      end
    end

    context 'get trading_fee with group' do
      subject { TradingFee.for(group: order.member.group, market_id: order.market_id) }

      before do
        create(:trading_fee, market_id: :any, group: 'vip-1')
        create(:trading_fee, market_id: :btc_usd, group: :any)
        create(:trading_fee, market_id: :any, group: :any)
      end

      let(:order) { Order.new(member: member, market_id: :btc_usd) }

      it do
        expect(subject).to be_truthy
        expect(subject.market_id).to eq('btc_usd')
        expect(subject.group).to eq('any')
      end
    end

    context 'get trading_fee with market_id' do
      subject { TradingFee.for(group: order.member.group, market_id: order.market_id) }

      before do
        create(:trading_fee, market_id: :any, group: 'vip-0')
        create(:trading_fee, market_id: :btc_usd, group: :any)
        create(:trading_fee, market_id: :any, group: :any)
      end

      let(:order) { Order.new(member: member, market_id: :btc_eth) }

      it do
        expect(subject).to be_truthy
        expect(subject.market_id).to eq('any')
        expect(subject.group).to eq('vip-0')
      end
    end

    context 'get default trading_fee' do
      subject { TradingFee.for(group: order.member.group, market_id: order.market_id) }

      before do
        create(:trading_fee, market_id: :any, group: 'vip-1')
        create(:trading_fee, market_id: :btc_usd, group: :any)
        create(:trading_fee, market_id: :any, group: :any)
      end

      let(:order) { Order.new(member: member, market_id: :btc_eth) }

      it do
        expect(subject).to be_truthy
        expect(subject.market_id).to eq('any')
        expect(subject.group).to eq('any')
      end
    end

    context 'get default trading_fee (doesnt create it)' do
      subject { TradingFee.for(group: order.member.group, market_id: order.market_id) }

      let(:order) { Order.new(member: member, market_id: :btc_eth) }

      it do
        expect(subject).to be_truthy
        expect(subject.market_id).to eq('any')
        expect(subject.group).to eq('any')
      end
    end
  end
end
