# encoding: UTF-8
# frozen_string_literal: true

describe Workers::AMQP::DepositCoinAddress do
  let(:member) { create(:member, :barong) }
  let(:address) { Faker::Blockchain::Bitcoin.address }
  let(:secret) { PasswordGenerator.generate(64) }
  let(:blockchain) { create(:blockchain, 'eth-rinkeby') }
  let(:payment_address) { member.payment_address(blockchain) }
  let(:create_address_result) do
    { address: address,
      secret: secret,
      details: { label: 'new-label' } }
  end

  subject { member.payment_address(blockchain).address }

  it 'raise error on databse connection error' do
    if defined? Mysql2
      Member.stubs(:find).raises(Mysql2::Error::ConnectionError.new(''))
      expect {
        Workers::AMQP::DepositCoinAddress.new.process(member_id: member.id, blockchain_id: blockchain.id)
      }.to raise_error Mysql2::Error::ConnectionError
    end

    if defined? PG
      Member.stubs(:find).raises(PG::Error.new(''))
      expect {
        Workers::AMQP::DepositCoinAddress.new.process(member_id: member.id, blockchain_id: blockchain.id)
      }.to raise_error PG::Error
    end
  end

  context 'blockchain service' do
    let(:address) { Faker::Blockchain::Ethereum.address }
    before do
      EthereumGateway::AddressCreator
        .any_instance
        .expects(:call)
        .returns(create_address_result)
    end

    it 'is passed to blockchain service' do
      Workers::AMQP::DepositCoinAddress.new.process(member_id: member.id, blockchain_id: blockchain.id)
      expect(subject).to eq address
      payment_address.reload
      expect(payment_address.as_json
               .deep_symbolize_keys
               .slice(:address, :secret, :details)).to eq(create_address_result)
    end

    context 'empty address details' do
      let(:create_address_result) do
        { address: address,
          secret: secret }
      end

      it 'is passed to blockchain service' do
        Workers::AMQP::DepositCoinAddress.new.process(member_id: member.id, blockchain_id: blockchain.id)
        expect(subject).to eq address
        payment_address.reload
        expect(payment_address.as_json
                 .deep_symbolize_keys
                 .slice(:address, :secret, :details)).to eq(create_address_result.merge(details: {}))
      end
    end

    context 'should skip address with details' do
      let(:create_address_result) do
        { address: nil,
          secret: secret,
          details: {
            address_id: 'address_id'
          } }
      end

      it 'shouldnt create address' do
        Workers::AMQP::DepositCoinAddress.new.process(member_id: member.id, blockchain_id: blockchain.id)
        expect(subject).to eq nil
        payment_address.reload
        expect(payment_address.as_json
                 .deep_symbolize_keys
                 .slice(:address, :secret, :details)).to eq(create_address_result.merge(details: {:address_id=>'address_id'}))
      end
    end
  end
end
