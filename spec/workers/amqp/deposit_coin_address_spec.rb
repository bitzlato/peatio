# frozen_string_literal: true

describe Workers::AMQP::DepositCoinAddress do
  subject { member.payment_address(blockchain).address }

  let(:member) { create(:member, :barong) }
  let(:address) { Faker::Blockchain::Ethereum.address }
  let(:blockchain) { create(:blockchain, 'eth-rinkeby') }
  let(:payment_address) { member.payment_address(blockchain) }

  it 'raise error on databse connection error' do
    if defined? Mysql2
      Member.stubs(:find).raises(Mysql2::Error::ConnectionError.new(''))
      expect do
        described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
      end.to raise_error Mysql2::Error::ConnectionError
    end

    if defined? PG
      Member.stubs(:find).raises(PG::Error.new(''))
      expect do
        described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
      end.to raise_error PG::Error
    end
  end

  context 'when USE_PRIVATE_KEY is true' do
    around do |example|
      ENV['USE_PRIVATE_KEY'] = 'true'
      example.run
      ENV.delete('USE_PRIVATE_KEY')
    end

    it 'is passed to blockchain service' do
      BelomorClient.any_instance.expects(:deposit_address).returns({ currencies: [], address: address, state: 'active', app_key: 'peatio' })
      described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
      expect(subject).to eq address
      payment_address.reload
      expect(payment_address).to have_attributes(address: address)
    end
  end

  context 'when member has same type address' do
    it 'sets common address to payment address' do
      ropsten_blockchain = create(:blockchain, 'eth-ropsten')
      blockchain_address = create(:blockchain_address)
      member.payment_address(ropsten_blockchain).update!(address: blockchain_address.address)
      described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
      expect(payment_address.reload).to have_attributes(address: blockchain_address.address.downcase)
    end
  end
end
