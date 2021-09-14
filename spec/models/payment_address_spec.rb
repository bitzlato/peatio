# encoding: UTF-8
# frozen_string_literal: true

describe PaymentAddress do
  context '.create' do
    let(:member)  { create(:member, :level_3) }
    let!(:account) { member.get_account(:btc) }
    let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'btc-testnet' }
    let(:secret) { 's3cr3t' }
    let(:details) { { 'a' => 'b', 'b' => 'c' } }
    let!(:addr) { create(:payment_address, :btc_address, address: nil, secret: secret, blockchain_id: blockchain.id) }

    it 'generate address after commit' do
      AMQP::Queue.expects(:enqueue).with(:deposit_coin_address, { member_id: member.id, blockchain_id: blockchain.id }, { persistent: true })
      member.payment_address(blockchain)
    end

    it 'updates secret' do
      expect do
        addr.update(secret: 'new_secret')
      end.to change { addr.reload.secret_encrypted }.and change { addr.reload.secret }.to 'new_secret'
    end

    it 'updates details' do
      expect do
        addr.update(details: details)
      end.to change { addr.reload.details_encrypted }.and change { addr.reload.details }.to details
    end

    it 'long secret' do
      expect do
        addr.update(secret: Faker::String.random(1024))
      end.to raise_error ActiveRecord::ValueTooLong
    end

    it 'long details' do
      expect do
        addr.update(details: { test: Faker::String.random(1024) })
      end.to raise_error ActiveRecord::ValueTooLong
    end
  end

  context 'methods' do
    context 'status' do
      let(:member)  { create(:member, :level_3) }
      let!(:account) { member.get_account(:btc) }
      let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'btc-testnet' }

      context 'pending' do
        let!(:addr) { create(:payment_address, :btc_address, address: nil, blockchain_id: blockchain.id) }

        it { expect(addr.status).to eq 'pending' }
      end

      context 'active' do
        let!(:addr) { create(:payment_address, :btc_address, blockchain_id: blockchain.id) }

        it { expect(addr.status).to eq 'active' }
      end

      context 'disabled' do
        before do
          blockchain.update(status: 'disabled')
        end

        let!(:addr) { create(:payment_address, :btc_address, blockchain_id: blockchain.id) }

        it { expect(addr.status).to eq 'disabled' }
      end
    end
  end
end
