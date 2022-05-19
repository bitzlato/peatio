# frozen_string_literal: true

RSpec.describe Workers::AMQP::WithdrawalProcessor do
  let(:member) { create(:member) }
  let(:withdrawal) { create(:eth_withdraw, member: member) }

  before do
    create(:account, :eth, member: member, balance: 100)
    withdrawal.accept!
  end

  context 'when event has confirming status' do
    let(:txid) { '0x0' }

    it 'dispatches withdrawal' do
      described_class.new.process({ 'remote_id' => withdrawal.id, 'status' => 'confirming', 'txid' => txid, 'owner_id' => "user:#{member.uid}" })
      expect(withdrawal.reload).to have_attributes(aasm_state: 'confirming', txid: txid)
    end
  end

  context 'when event has succeed status' do
    it 'successes withdrawal' do
      withdrawal.transfer!
      withdrawal.update!(txid: '0x0')
      withdrawal.dispatch!
      described_class.new.process({ 'remote_id' => withdrawal.id, 'status' => 'succeed', 'owner_id' => "user:#{member.uid}", 'currency' => withdrawal.currency_id, 'amount' => withdrawal.sum.to_s, 'blockchain_key' => withdrawal.blockchain.key })
      expect(withdrawal.reload).to have_attributes(aasm_state: 'succeed', is_locked: false)
    end
  end
end
