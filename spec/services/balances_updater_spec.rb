# frozen_string_literal: true

RSpec.describe BalancesUpdater do
  subject(:service) { described_class.new(blockchain: blockchain, address: address) }

  describe '#perform' do
    let(:blockchain) { find(:blockchain, key: 'eth-rinkeby') }

    before do
      (0..2).each do |i|
        stub_balance_fetching(blockchain_currency: blockchain.blockchain_currencies[i], balance: 511_823_000_420_000_000, address: address, id: i + 1)
      end
    end

    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    context 'with address of payment address' do
      let(:payment_address) { create(:eth_payment_address, blockchain: blockchain) }
      let(:address) { payment_address.address }

      it 'updates payment address balances' do
        service.perform
        expect(payment_address.reload.balances).to eq('eth' => '0.51182300042', 'ring' => '511823000420.0', 'trst' => '511823000420.0')
      end
    end

    context 'with address of wallet' do
      let(:wallet) { create :wallet, :eth_hot, name: generate(:wallet_name), balance: { 'eth' => '0.1' } }
      let(:address) { wallet.address }

      it { expect(wallet.currencies).to include(Currency.find('eth')) }

      it 'updates wallet balances' do
        service.perform
        expect(wallet.reload.balance).to eq('eth' => '0.51182300042')
      end
    end
  end
end
