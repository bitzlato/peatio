# frozen_string_literal: true

RSpec.describe Workers::AMQP::DepositProcessor do
  let(:member) { create(:member) }
  let(:blockchain) { find_or_create(:blockchain, 'eth-rinkeby', key: 'eth-rinkeby') }
  let(:currency) { find_or_create(:currency, 'eth', id: 'eth') }
  let(:txid) { '0x9b9a804676abb75d4afd4a961ead163ea1b96d00766ff24fb382aff2596ae150' }
  let(:txout) { nil }
  let(:amount) { 0.01.to_d }

  context 'with confirmations count less than min_confirmations' do
    it 'creates deposit' do
      described_class.new.process(
        owner_id: "user:#{member.uid}",
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        confirmations: 1
      )
      expect(Deposit.find_by(blockchain: blockchain, txid: txid)).to have_attributes(currency_id: currency.id, amount: amount, txout: txout, member: member, aasm_state: 'submitted')
    end
  end

  context 'with confirmations count more or equal than min_confirmations' do
    it 'acceptes deposit' do
      deposit = create(:deposit, :deposit_eth, blockchain: blockchain, currency: currency, txid: txid, txout: txout, amount: amount, member: member, aasm_state: 'submitted')
      described_class.new.process(
        owner_id: "user:#{member.uid}",
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        confirmations: 6
      )
      expect(deposit.reload).to have_attributes(aasm_state: 'accepted')
    end
  end
end
