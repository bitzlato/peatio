# frozen_string_literal: true

describe AdminAbility do
  context 'abilities for superadmin' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'superadmin') }

    it do
      expect(subject).to be_able_to(:manage, Account.new)
      expect(subject).to be_able_to(:manage, Currency.new)
      expect(subject).to be_able_to(:manage, Deposit.new)
      expect(subject).to be_able_to(:manage, Withdraw.new)
      expect(subject).to be_able_to(:manage, Operations::Account.new)
      expect(subject).to be_able_to(:manage, Operations::Asset.new)
      expect(subject).to be_able_to(:manage, Operations::Expense.new)
      expect(subject).to be_able_to(:manage, Operations::Liability.new)
      expect(subject).to be_able_to(:manage, Operations::Revenue.new)
      expect(subject).to be_able_to(:manage, Market.new)
      expect(subject).to be_able_to(:manage, Blockchain.new)
      expect(subject).to be_able_to(:manage, Wallet.new)
      expect(subject).to be_able_to(:manage, PaymentAddress.new)
      expect(subject).to be_able_to(:manage, Member.new)
      expect(subject).to be_able_to(:manage, WhitelistedSmartContract.new)

      expect(subject).to be_able_to(:read, Account.new)
      expect(subject).to be_able_to(:read, Currency.new)
      expect(subject).to be_able_to(:read, Deposit.new)
      expect(subject).to be_able_to(:read, Withdraw.new)
      expect(subject).to be_able_to(:read, Operations::Account.new)
      expect(subject).to be_able_to(:read, Operations::Asset.new)
      expect(subject).to be_able_to(:read, Operations::Expense.new)
      expect(subject).to be_able_to(:read, Operations::Liability.new)
      expect(subject).to be_able_to(:read, Operations::Revenue.new)
      expect(subject).to be_able_to(:read, Market.new)
      expect(subject).to be_able_to(:read, Blockchain.new)
      expect(subject).to be_able_to(:read, Wallet.new)
      expect(subject).to be_able_to(:read, PaymentAddress.new)
      expect(subject).to be_able_to(:read, Member.new)

      expect(subject).to be_able_to(:update, Account.new)
      expect(subject).to be_able_to(:update, Currency.new)
      expect(subject).to be_able_to(:update, Deposit.new)
      expect(subject).to be_able_to(:update, Withdraw.new)
      expect(subject).to be_able_to(:update, Operations::Account.new)
      expect(subject).to be_able_to(:update, Operations::Asset.new)
      expect(subject).to be_able_to(:update, Operations::Expense.new)
      expect(subject).to be_able_to(:update, Operations::Liability.new)
      expect(subject).to be_able_to(:update, Operations::Revenue.new)
      expect(subject).to be_able_to(:update, Market.new)
      expect(subject).to be_able_to(:update, Blockchain.new)
      expect(subject).to be_able_to(:update, Wallet.new)
      expect(subject).to be_able_to(:update, PaymentAddress.new)
      expect(subject).to be_able_to(:update, Member.new)

      expect(subject).to be_able_to(:read, Order.new)
      expect(subject).to be_able_to(:update, Order.new)
      expect(subject).to be_able_to(:read, Trade.new)
      expect(subject).not_to be_able_to(:update, Trade.new)
    end
  end

  context 'abilities for admin' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'admin') }

    it do
      expect(subject).to be_able_to(:manage, Currency.new)
      expect(subject).to be_able_to(:manage, Deposit.new)
      expect(subject).to be_able_to(:manage, Withdraw.new)
      expect(subject).to be_able_to(:manage, Operations::Account.new)
      expect(subject).to be_able_to(:manage, Operations::Asset.new)
      expect(subject).to be_able_to(:manage, Operations::Expense.new)
      expect(subject).to be_able_to(:manage, Operations::Liability.new)
      expect(subject).to be_able_to(:manage, Operations::Revenue.new)
      expect(subject).to be_able_to(:manage, Account.new)
      expect(subject).to be_able_to(:manage, Market.new)
      expect(subject).to be_able_to(:manage, Blockchain.new)
      expect(subject).to be_able_to(:manage, Wallet.new)
      expect(subject).to be_able_to(:manage, PaymentAddress.new)
      expect(subject).to be_able_to(:read, PaymentAddress.new)
      expect(subject).to be_able_to(:read, Member.new)
      expect(subject).to be_able_to(:update, Member.new)
      expect(subject).to be_able_to(:read, Order.new)
      expect(subject).to be_able_to(:update, Order.new)
      expect(subject).to be_able_to(:read, Trade.new)
      expect(subject).not_to be_able_to(:update, Trade.new)
    end
  end

  context 'abilities for compliance' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'compliance') }

    it do
      expect(subject).to be_able_to(:read, Account.new)
      expect(subject).to be_able_to(:read, Deposit.new)
      expect(subject).to be_able_to(:read, Withdraw.new)
      expect(subject).to be_able_to(:read, PaymentAddress.new)
      expect(subject).to be_able_to(:read, Operations::Account.new)
      expect(subject).to be_able_to(:read, Operations::Asset.new)
      expect(subject).to be_able_to(:read, Operations::Expense.new)
      expect(subject).to be_able_to(:read, Operations::Liability.new)
      expect(subject).to be_able_to(:read, Member.new)
    end
  end

  context 'abilities for support' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'support') }

    it do
      expect(subject).to be_able_to(:read, Account.new)
      expect(subject).to be_able_to(:read, Deposit.new)
      expect(subject).to be_able_to(:read, Withdraw.new)
      expect(subject).to be_able_to(:read, Member.new)
      expect(subject).not_to be_able_to(:update, Member.new)
      expect(subject).not_to be_able_to(:update, Account.new)
      expect(subject).not_to be_able_to(:update, Deposit.new)
      expect(subject).not_to be_able_to(:update, Withdraw.new)
      expect(subject).not_to be_able_to(:update, PaymentAddress.new)
    end
  end

  context 'abilities for technical' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'technical') }

    it do
      expect(subject).to be_able_to(:manage, Market.new)
      expect(subject).to be_able_to(:manage, Currency.new)
      expect(subject).to be_able_to(:manage, Blockchain.new)
      expect(subject).to be_able_to(:manage, Wallet.new)
      expect(subject).to be_able_to(:read, Member.new)
      expect(subject).to be_able_to(:manage, Engine.new)
      expect(subject).to be_able_to(:manage, TradingFee.new)
      expect(subject).to be_able_to(:read, Operations::Account.new)
      expect(subject).to be_able_to(:read, Operations::Asset.new)
      expect(subject).to be_able_to(:read, Operations::Expense.new)
      expect(subject).to be_able_to(:read, Operations::Liability.new)
      expect(subject).to be_able_to(:read, Order.new)
      expect(subject).to be_able_to(:read, Trade.new)
      expect(subject).to be_able_to(:read, Member.new)
    end
  end

  context 'abilities for reporter' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'reporter') }

    it do
      expect(subject).to be_able_to(:read, Deposit.new)
      expect(subject).to be_able_to(:read, Operations::Account.new)
      expect(subject).to be_able_to(:read, Operations::Asset.new)
      expect(subject).to be_able_to(:read, Operations::Expense.new)
      expect(subject).to be_able_to(:read, Operations::Liability.new)
      expect(subject).to be_able_to(:read, Withdraw.new)
      expect(subject).to be_able_to(:read, Currency.new)
      expect(subject).to be_able_to(:read, Wallet.new)
      expect(subject).to be_able_to(:read, Blockchain.new)
    end
  end

  context 'abilities for accountant' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'accountant') }

    it do
      expect(subject).to be_able_to(:read, Deposit.new)
      expect(subject).to be_able_to(:read, Withdraw.new)
      expect(subject).to be_able_to(:read, Account.new)
      expect(subject).to be_able_to(:read, PaymentAddress.new)
      expect(subject).to be_able_to(:read, Operations::Account.new)
      expect(subject).to be_able_to(:read, Operations::Asset.new)
      expect(subject).to be_able_to(:read, Operations::Expense.new)
      expect(subject).to be_able_to(:read, Operations::Liability.new)
      expect(subject).to be_able_to(:read, Operations::Revenue.new)
      expect(subject).to be_able_to(:read, Member.new)
      expect(subject).to be_able_to(:read, Deposit.new)
      expect(subject).to be_able_to(:create, Deposits::Fiat.new)
      expect(subject).to be_able_to(:create, Adjustment.new)
    end
  end

  context 'abilities for member' do
    subject(:ability) { described_class.new(member) }

    let(:member) { create(:member, role: 'member') }

    it do
      expect(subject).not_to be_able_to(:read, Account.new)
      expect(subject).not_to be_able_to(:read, Currency.new)
      expect(subject).not_to be_able_to(:read, Deposit.new)
      expect(subject).not_to be_able_to(:read, Withdraw.new)
      expect(subject).not_to be_able_to(:read, Operations::Account.new)
      expect(subject).not_to be_able_to(:read, Operations::Asset.new)
      expect(subject).not_to be_able_to(:read, Operations::Expense.new)
      expect(subject).not_to be_able_to(:read, Operations::Liability.new)
      expect(subject).not_to be_able_to(:read, Operations::Revenue.new)
      expect(subject).not_to be_able_to(:read, Market.new)
      expect(subject).not_to be_able_to(:read, Blockchain.new)
      expect(subject).not_to be_able_to(:read, Wallet.new)
      expect(subject).not_to be_able_to(:read, PaymentAddress.new)
      expect(subject).not_to be_able_to(:read, Member.new)

      expect(subject).not_to be_able_to(:update, Account.new)
      expect(subject).not_to be_able_to(:update, Currency.new)
      expect(subject).not_to be_able_to(:update, Deposit.new)
      expect(subject).not_to be_able_to(:update, Withdraw.new)
      expect(subject).not_to be_able_to(:update, Operations::Account.new)
      expect(subject).not_to be_able_to(:update, Operations::Asset.new)
      expect(subject).not_to be_able_to(:update, Operations::Expense.new)
      expect(subject).not_to be_able_to(:update, Operations::Liability.new)
      expect(subject).not_to be_able_to(:update, Operations::Revenue.new)
      expect(subject).not_to be_able_to(:update, Market.new)
      expect(subject).not_to be_able_to(:update, Blockchain.new)
      expect(subject).not_to be_able_to(:update, Wallet.new)
      expect(subject).not_to be_able_to(:update, PaymentAddress.new)
      expect(subject).not_to be_able_to(:update, Member.new)

      expect(subject).not_to be_able_to(:destroy, Account.new)
      expect(subject).not_to be_able_to(:destroy, Currency.new)
      expect(subject).not_to be_able_to(:destroy, Deposit.new)
      expect(subject).not_to be_able_to(:destroy, Withdraw.new)
      expect(subject).not_to be_able_to(:destroy, Operations::Account.new)
      expect(subject).not_to be_able_to(:destroy, Operations::Asset.new)
      expect(subject).not_to be_able_to(:destroy, Operations::Expense.new)
      expect(subject).not_to be_able_to(:destroy, Operations::Liability.new)
      expect(subject).not_to be_able_to(:destroy, Operations::Revenue.new)
      expect(subject).not_to be_able_to(:destroy, Market.new)
      expect(subject).not_to be_able_to(:destroy, Blockchain.new)
      expect(subject).not_to be_able_to(:destroy, Wallet.new)
      expect(subject).not_to be_able_to(:destroy, PaymentAddress.new)
      expect(subject).not_to be_able_to(:destroy, Member.new)
    end
  end
end
