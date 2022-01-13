# frozen_string_literal: true

require './spec/gateways/shared_solana'

describe ::SolanaGateway, :solana do
  # before do
  #   Blockchain.any_instance.stubs(:hot_wallet).returns(solana_hot_wallet)
  # end

  describe '#create_address!' do
    it 'creates BlockchainAddress' do
      expect do
        result = solana_gateway.create_address!
        expect(result[:address]).to be_present
        expect(BlockchainAddress.find_by(address: result[:address], address_type: solana_gateway.class.address_type)).to be_present
      end.to change(BlockchainAddress, :count).by(1)
    end
  end
end
