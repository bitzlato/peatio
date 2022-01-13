# frozen_string_literal: true

require './spec/gateways/shared_solana'

describe ::SolanaGateway::BalanceLoader, :solana do
  describe '#load_balance' do
    describe "native address"
    it 'returns balance for native' do
      VCR.use_cassette('solana/load_balance_native', record: :once) do
        amount = solana_gateway.load_balance(solana_hot_wallet.address, sol)
        expect(amount.to_f).to eq(0.95092228)
      end
    end

    it 'not returns balance for token' do
      amount = solana_gateway.load_balance(solana_hot_wallet.address, sol_spl)
      expect(amount.to_f).to eq(0)
    end

    describe "token address" do
      it 'returns balance for native' do
        VCR.use_cassette('solana/load_balance_contract_native', record: :once) do
          amount = solana_gateway.load_balance(solana_spl_payment_address.address, sol)
          expect(amount.to_f).to eq(0.00203928)
        end
      end

      it 'returns balance for token' do
        VCR.use_cassette('solana/load_balance_contract_token', record: :once) do
          solana_spl_payment_address
          amount = solana_gateway.load_balance(solana_spl_payment_address.address, sol_spl)
          expect(amount.to_f).to eq(1.25)
        end
      end
    end
  end
end
