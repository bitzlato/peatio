# frozen_string_literal: true

describe ::TronGateway do
  subject(:gateway) { described_class.new(blockchain) }

  let(:hot_wallet) { find_or_create :wallet, :trx_hot, name: 'Tron Hot Wallet' }
  let(:blockchain) { hot_wallet.blockchain }

  before do
    Blockchain.any_instance.stubs(:hot_wallet).returns(hot_wallet)
  end

  describe '#create_address!' do
    it 'creates BlockchainAddress' do
      expect do
        result = gateway.create_address!
        expect(result[:address]).to be_present
        expect(BlockchainAddress.find_by(address: result[:address], address_type: gateway.class.address_type)).to be_present
      end.to change(BlockchainAddress, :count).by(1)
    end
  end
end
