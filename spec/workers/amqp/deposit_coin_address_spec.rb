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
    before do
      ENV['USE_PRIVATE_KEY'] = 'true'
      Eth::Key
        .any_instance
        .expects(:address)
        .returns(address)
      Eth::Key
        .any_instance
        .expects(:private_hex)
        .returns('private_hex')
    end

    after do
      ENV.delete('USE_PRIVATE_KEY')
    end

    it 'is passed to blockchain service' do
      described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
      expect(subject).to eq address
      payment_address.reload
      expect(payment_address).to have_attributes(address: address)
    end
  end

  context 'when USE_PRIVATE_KEY is not true' do
    let(:secret) { PasswordGenerator.generate(64) }
    let(:create_address_result) do
      { address: address,
        secret: secret,
        details: { label: 'new-label' } }
    end

    before do
      EthereumGateway::AddressCreator
        .any_instance
        .expects(:call)
        .returns(create_address_result)
    end

    it 'is passed to blockchain service' do
      described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
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
        described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
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
        described_class.new.process(member_id: member.id, blockchain_id: blockchain.id)
        expect(subject).to eq nil
        payment_address.reload
        expect(payment_address.as_json
          .deep_symbolize_keys
          .slice(:address, :secret, :details)).to eq(create_address_result.merge(details: { address_id: 'address_id' }))
      end
    end
  end
end
