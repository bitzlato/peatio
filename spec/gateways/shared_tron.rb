# frozen_string_literal: true

RSpec.shared_context 'shared tron' do
  let!(:hot_wallet) { find_or_create :wallet, :trx_hot, name: 'Tron Hot Wallet(Shared)' }
  let(:blockchain)    { hot_wallet.blockchain }
  let(:gateway)       { TronGateway.new(blockchain) }
  let!(:trx)           { find_or_create(:currency, :trx, id: :trx) }
  let!(:usdj_trc20)  { find_or_create(:currency, :'usdj-trc20', id: :'usdj-trc20') }
  let(:fee_currency) { blockchain.fee_currency }
  let!(:payment_address) do
    address = 'TLiwXKmPRS8EuBgp35soVwAtuPFE94moxc'
    private_key = '5c0c887905fcb0821721c17ff9a1c28501c3f96f4d07a4b7160ddb32587a663d'

    find_or_create(:payment_address, blockchain: blockchain, address: address).tap do |_pm|
      create :blockchain_address, address: address, private_key_hex: private_key, address_type: gateway.class.address_type
    end
  end
end
