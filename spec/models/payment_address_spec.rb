# frozen_string_literal: true

describe PaymentAddress do
  let!(:blockchain) { find_or_create :blockchain, 'eth-rinkeby', key: 'eth-rinkeby' }

  describe '.create' do
    let(:member) { create(:member, :level_3) }
    let!(:account) { member.get_account(:eth) }
    let(:details) { { 'a' => 'b', 'b' => 'c' } }
    let(:secret) { 's3cr3t' }
    let!(:pa) { create(:payment_address, :eth_address, address: nil, secret: secret, blockchain_id: blockchain.id) }

    it 'generate address after commit' do
      pa.update_column :enqueued_generation_at, nil
      AMQP::Queue.expects(:enqueue)
                 .with(:deposit_coin_address, { member_id: member.id, blockchain_id: blockchain.id })
      member.payment_address(blockchain)
    end

    it 'updates secret' do
      expect do
        pa.update(secret: 'new_secret')
      end.to change { pa.reload.secret_encrypted }.and change { pa.reload.secret }.to 'new_secret'
    end

    it 'updates details' do
      expect do
        pa.update(details: details)
      end.to change { pa.reload.details_encrypted }.and change { pa.reload.details }.to details
    end

    it 'long secret' do
      expect do
        pa.update(secret: Faker::String.random(1024))
      end.to raise_error ActiveRecord::ValueTooLong
    end

    it 'long details' do
      expect do
        pa.update(details: { test: Faker::String.random(1024) })
      end.to raise_error ActiveRecord::ValueTooLong
    end
  end

  context 'methods' do
    context 'status' do
      let(:member) { create(:member, :level_3) }
      let!(:account) { member.get_account(:eth) }
      let!(:blockchain) { FactoryBot.find_or_create :blockchain, 'eth-rinkeby' }

      context 'pending' do
        let!(:pa) { create(:payment_address, :eth_address, address: nil, blockchain_id: blockchain.id) }

        it { expect(pa.status).to eq 'pending' }
      end

      context 'active' do
        let!(:pa) { create(:payment_address, :eth_address, blockchain_id: blockchain.id) }

        it { expect(pa.status).to eq 'active' }
      end

      context 'disabled' do
        before do
          blockchain.update(status: 'disabled')
        end

        let!(:pa) { create(:payment_address, :eth_address, blockchain_id: blockchain.id) }

        it { expect(pa.status).to eq 'disabled' }
      end
    end
  end

  context 'collect!' do
    let!(:pa) { create(:eth_payment_address, blockchain_id: blockchain.id) }

    it do
      EthereumGateway.any_instance.expects(:collect!)
      pa.collect!
    end
  end
end
