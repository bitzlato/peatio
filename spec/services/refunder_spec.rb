# encoding: UTF-8
# frozen_string_literal: true

describe Refunder do
  pending
  # let!(:blockchain) { create(:blockchain, 'fake-testnet') }
  # let!(:currency) { create(:currency, :fake) }
  # let(:wallet) { create(:wallet, :fake_hot) }
  # let(:member) { create(:member) }

  # let(:fake_wallet_adapter) { FakeWallet.new }
  # let(:fake_blockchain_adapter) { FakeBlockchain.new }

  # let(:service) { WalletService.new(wallet) }

  # before do
  # Peatio::Blockchain.registry.expects(:[])
  # .with(:fake)
  # .returns(fake_blockchain_adapter.class)
  # .at_least_once

  # Peatio::Wallet.registry.expects(:[])
  # .with(:fake)
  # .returns(fake_wallet_adapter.class)
  # .at_least_once

  # Blockchain.any_instance.stubs(:blockchain_api).returns(BlockchainService.new(blockchain))
  # end

  # context :refund do
  # let!(:deposit_wallet) { create(:wallet, :fake_deposit) }

  # let(:amount) { 2 }
  # let(:refund_deposit) { create(:deposit_btc, amount: amount, currency: currency) }

  # let(:fake_wallet_adapter) { FakeWallet.new }
  # let(:service) { WalletService.new(deposit_wallet) }

  # let(:transaction) do
  # Peatio::Transaction.new(hash:        '0xfake',
  # to_address:  'user_address',
  # amount:      refund_deposit.amount,
  # currency_id: currency.id)
  # end

  # let!(:refund) { Refund.create(deposit: refund_deposit, address: 'user_address') }

  # subject { service.refund!(refund) }

  # before do
  # refund_deposit.member.payment_address(blockchain).update(address: refund_deposit.address)
  # service.adapter.expects(:create_transaction!).returns(transaction)
  # end

  # it 'creates single transaction' do
  # expect(subject).to eq(transaction)
  # expect(subject).to be_a(Peatio::Transaction)
  # end
  # end
end
