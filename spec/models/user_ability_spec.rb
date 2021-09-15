# frozen_string_literal: true

describe UserAbility do
  context 'abilities for member' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'member') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for superadmin' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'superadmin') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for admin' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'admin') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for compliance' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'compliance') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for support' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'support') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for technical' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'technical') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for reporter' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'reporter') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for accountant' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'accountant') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for broker' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'broker') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for trader' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'trader') }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'abilities for maker' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'maker') }

    it { is_expected.to be_able_to(:manage, :all) }
  end
end
