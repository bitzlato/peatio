# frozen_string_literal: true

describe InternalTransfer do
  let(:member) { create :member }

  let!(:currency_usdt) { create :currency, code: 'usdt' }
  let!(:currency_usdt_erc20) { create :currency, code: 'usdt-erc20' }

  let(:account_usdt) { member.get_account('usdt') }
  let(:account_usdt_erc20) { member.get_account('usdt-erc20') }

  let(:amount) { 100 }

  before do
    account_usdt_erc20.update! balance: amount
  end

  it { expect(account_usdt_erc20.balance).to eq amount }
  it { expect(account_usdt.balance).to be_zero }

  context 'transfer legacy currency' do
    before do
      InternalTransfer.create!(receiver: member,
                               sender: member,
                               amount: amount,
                               currency: currency_usdt_erc20)
    end

    it { expect(InternalTransfer.count).to eq 1 }
    it { expect(account_usdt_erc20.reload.balance).to be_zero }
    it { expect(account_usdt.reload.balance).to eq amount }
  end
end
