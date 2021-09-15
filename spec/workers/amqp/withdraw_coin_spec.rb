# frozen_string_literal: true

describe Workers::AMQP::WithdrawCoin do
  let(:withdrawal) { create(:btc_withdraw, :with_deposit_liability) }

  context 'withdrawal does not exist' do
    before { Withdraw.expects(:find_by_id).returns(nil) }

    it 'returns nil' do
      expect(described_class.new.process(withdrawal.as_json)).to be(nil)
    end
  end

  context 'withdrawal is not in processing state' do
    it 'returns nil' do
      expect(described_class.new.process(withdrawal.as_json)).to be(nil)
    end
  end
end
