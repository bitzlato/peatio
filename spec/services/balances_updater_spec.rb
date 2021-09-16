# frozen_string_literal: true

RSpec.describe BalancesUpdater do
  subject(:service) { described_class.new(blockchain: blockchain, address: address) }

  describe '#perform' do
    let(:blockchain) { find(:blockchain, key: 'eth-rinkeby') }

    before do
      (1..3).each do |id|
        stub_request(:post, 'http://127.0.0.1:8545')
          .with(body: { jsonrpc: '2.0',
                        id: id,
                        method: :eth_getBalance,
                        params: [address, 'latest'] }.to_json)
          .to_return(body: { jsonrpc: '2.0', result: '0x71a5c4e9fe8a100', id: id }.to_json)
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
      let(:wallet) { find(:wallet, name: 'Ethereum Deposit Wallet') }
      let(:address) { wallet.address }

      it 'updates wallet balances' do
        service.perform
        expect(wallet.reload.balance).to eq('eth' => '0.51182300042')
      end
    end
  end
end
