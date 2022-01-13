# frozen_string_literal: true

require './spec/gateways/shared_solana'

describe ::SolanaGateway::Collector, :solana do
  describe '#collect_all!' do
    describe "sol_account" do
      it 'collects native' do
        VCR.use_cassette('solana/collect_native', record: :once) do
          result = solana_gateway.collect!(solana_payment_address)
          expect(result).to eq(["5nLNiT3rVEbrTFUYtm86AnmaEdxvp6UYQrvMEz6p4xTAhx7G93xDDqy47qbnofS5JRx9VQwi7zLP5G2BLCjBhBKs"])
        end
      end
    end

    describe "token account" do
      it 'collects tokens' do
        VCR.use_cassette('solana/collect_token', record: :once) do
          solana_gateway.collect!(solana_spl_payment_address)
        end
      end
    end
  end
end
