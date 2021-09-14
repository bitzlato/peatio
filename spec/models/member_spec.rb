# frozen_string_literal: true

describe Member do
  subject { member }

  let(:member) { build(:member, :level_3) }

  describe 'uid' do
    subject(:member) { create(:member, :level_3) }

    it do
      expect(member.uid).not_to be_nil
      expect(member.uid).not_to be_empty
      expect(member.uid).to match(/\AID[A-Z0-9]{10}$/)
    end
  end

  describe 'username' do
    subject(:member) { create(:member, username: 'foobar') }

    it do
      expect(member.username).not_to be_nil
      expect(member.username).not_to be_empty
      expect(member.username).to eq 'foobar'
    end
  end

  describe 'before_create' do
    it 'unifies email' do
      create(:member, email: 'foo@example.com')
      expect(build(:member, email: 'Foo@example.com')).not_to be_valid
    end

    it 'doesnt creates accounts for the member' do
      expect do
        member.save!
      end.not_to change(member.accounts, :count)
    end
  end

  describe '#trades' do
    subject { create(:member, :level_3) }

    it 'finds all trades belong to user' do
      ask = create(:order_ask, :btc_usd, member: member)
      bid = create(:order_bid, :btc_usd, member: member)
      t1 = create(:trade, :btc_usd, maker_order: ask)
      t2 = create(:trade, :btc_usd, taker_order: bid)
      expect(member.trades.order('id')).to eq [t1, t2]
    end
  end
end
