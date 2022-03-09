# frozen_string_literal: true

require './spec/gateways/shared_solana'

describe ::SolanaGateway::TokenAddressCreator, :solana do
  describe '#find_or_create_token_account' do
    it 'creates new account' do
      VCR.use_cassette('solana/token_address_creator_new', record: :once) do
        address = solana_gateway.find_or_create_token_account(solana_payment_address.address, solana_spl_blockchain_currency.contract_address, solana_blockchain.hot_wallet)
        expect(address).to eq(solana_contract_payment_address)
      end
    end

    it 'returns existed account' do
      VCR.use_cassette('solana/token_address_creator_existed', record: :once) do
        address = solana_gateway.find_or_create_token_account(solana_payment_address.address, solana_spl_blockchain_currency.contract_address, solana_blockchain.hot_wallet)
        expect(address).to eq(solana_contract_payment_address)
      end
    end
  end
end