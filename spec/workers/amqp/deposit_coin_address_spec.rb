# frozen_string_literal: true

describe Workers::AMQP::DepositCoinAddress do
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

  context 'when belomor returns address' do
    before do
      BelomorClient.any_instance.expects(:create_address).returns({ 'address' => address })
    end

    it 'sets address to payment_address' do
      described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
      expect(payment_address.reload).to have_attributes(address: address)
    end
  end
end
