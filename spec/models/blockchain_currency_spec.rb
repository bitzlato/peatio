# frozen_string_literal: true

RSpec.describe BlockchainCurrency do
  context 'token' do
    let!(:blockchain_currency) { described_class.find_by!(currency: Currency.find(:ring)) }
    let!(:trst_blockchain_currency) { described_class.find_by!(currency: Currency.find(:trst)) }
    let!(:fiat_blockchain_currency) { described_class.find_by!(currency: Currency.find(:eur)) }

    # coin configuration
    it 'validate parent_id presence' do
      blockchain_currency.parent_id = nil
      expect(blockchain_currency.valid?).to eq true
    end

    # token configuration
    it 'validate parent_id value' do
      blockchain_currency.parent_id = fiat_blockchain_currency.id
      expect(blockchain_currency).not_to be_valid
      expect(blockchain_currency.errors[:parent_id]).to eq ['wrong fiat/crypto nesting']

      blockchain_currency.parent_id = trst_blockchain_currency.id
      expect(blockchain_currency).not_to be_valid
      expect(blockchain_currency.errors[:parent_id]).to eq ['wrong parent blockchain currency']
    end
  end

  context 'Callbacks' do
    context 'after_create' do
      context 'link_wallets' do
        let!(:coin) { Currency.find(:eth) }
        let!(:wallet) { Wallet.deposit_wallets(:eth)[0] }
        let(:currency) { create(:currency, code: 'test') }

        context 'without parent id' do
          it 'does not create currency wallet' do
            described_class.create!(blockchain: Blockchain.last, currency: currency)
            expect(CurrencyWallet.find_by(currency_id: currency.id, wallet_id: wallet.id)).to eq nil
          end
        end

        context 'with parent id' do
          it 'creates currency wallet' do
            described_class.create!(blockchain: coin.blockchain, currency: currency, contract_address: '0x0', parent_id: coin.blockchain_currency.id)
            c_w = CurrencyWallet.find_by(currency_id: currency.id, wallet_id: wallet.id)

            expect(c_w.present?).to eq true
            expect(c_w.currency_id).to eq currency.id
          end
        end
      end
    end
  end
end
