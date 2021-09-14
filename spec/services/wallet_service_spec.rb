# frozen_string_literal: true

describe 'WalletService' do
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

  # context :create_incentive_deposit! do
  # let(:wallet) { create :wallet, :fake_hot }
  # let(:amount) { 123 }

  # before do
  ## TODO Fix  undefined method `stub_const'
  ## stub_const('WalletService::ALLOWED_INCENTIVE_GATEWAY','fake')
  # WalletService.send(:remove_const, :ALLOWED_INCENTIVE_GATEWAY)
  # WalletService::ALLOWED_INCENTIVE_GATEWAY = 'fake'
  # end

  # it 'created accepted deposit' do
  # expect(
  # service.create_incentive_deposit!(member: member, amount: amount, currency: currency)
  # ).to be_accepted
  # end
  # end

  # context :create_invoice! do
  # let(:deposit) { create :deposit_btc, address: 'fake' }
  # let(:invoice_id) { 123 }
  # let(:wallet) { create :wallet, :fake_hot }
  # let(:fake_wallet_adapter) { Bitzlato::Wallet.new }
  # before do
  # Bitzlato::Wallet.any_instance.stubs(:create_invoice!).returns({ amount: deposit.amount, id: invoice_id, links: {}})
  # Wallet.any_instance.stubs(:settings).returns({ key: {}, uid: :some_acount_id, uri: 'uri' })
  # end

  # it 'calls extrenal service and save invoice_id' do
  # service.create_invoice! deposit
  # expect(deposit.invoice_id).to eq invoice_id.to_s
  # expect(deposit).to be_invoiced
  # end
  # end

  # context :poll_deposits! do
  # let(:member) { create(:member) }
  # let(:amount) { 1.12 }
  # let(:invoice_id) { 12 }
  # let(:username) { 'ivan' }
  # let(:wallet) { create :wallet, :fake_hot, save_beneficiary: true }
  # let!(:deposit) { create :deposit_btc, amount: amount, address: 'fake', currency: currency, invoice_id: invoice_id, aasm_state: :invoiced }

  # let(:intentions) { [
  # { id: invoice_id, amount: amount, address: username, currency: currency.id }
  # ] }

  # before do
  # service.adapter.expects(:poll_deposits).returns(intentions)
  # end

  # it 'accepts deposit' do
  # service.poll_deposits!
  # expect(deposit.reload).to be_accepted
  # end

  # it 'creates beneficiary' do
  # service.poll_deposits!
  # expect(deposit.account.member.beneficiaries.count).to eq(1)
  # end
  # end

  # context :build_withdrawal! do
  # let(:withdrawal) { create(:btc_withdraw, rid: 'fake-address', amount: 100, currency: currency, member: member) }

  # let(:transaction) do
  # Peatio::Transaction.new(hash:        '0xfake',
  # to_address:  withdrawal.rid,
  # amount:      withdrawal.amount,
  # currency_id: currency.id)
  # end

  # before do
  # member.get_account(currency).update!(balance: 1000)
  # service.adapter.expects(:create_transaction!).returns(transaction)
  # end

  # it 'sends withdrawal' do
  # expect(service.build_withdrawal!(withdrawal)).to eq transaction
  # end
  # end

  # context :collect_deposit do
  # before do
  # #Peatio::Blockchain.registry.expects(:[])
  # #.with(:bitcoin)
  # #.returns(fake_blockchain_adapter.class)
  # #.at_least_once
  # end

  # let!(:deposit_wallet) { create(:wallet, :fake_deposit) }
  # let!(:hot_wallet) { create(:wallet, :fake_hot) }
  # let!(:cold_wallet) { create(:wallet, :fake_cold) }

  # let(:amount) { 2 }
  # let(:deposit) { create(:deposit_btc, amount: amount, currency: currency) }

  # let(:fake_wallet_adapter) { FakeWallet.new }
  # let(:service) { WalletService.new(deposit_wallet) }

  # context 'Spread deposit with single entry' do

  # let(:spread_deposit) do
  # [Peatio::Transaction.new(to_address: 'fake-cold',
  # amount: '2.0',
  # currency_id: currency.id)]
  # end

  # let(:transaction) do
  # [Peatio::Transaction.new(hash:        '0xfake',
  # to_address:  cold_wallet.address,
  # amount:      deposit.amount,
  # currency_id: currency.id)]
  # end

  # subject { service.collect_deposit!(deposit, spread_deposit) }

  # before do
  # deposit.member.payment_address(blockchain).update(address: deposit.address)
  # service.adapter.expects(:create_transaction!).returns(transaction.first)
  # end

  # it 'creates single transaction' do
  # expect(subject).to contain_exactly(*transaction)
  # expect(subject).to all(be_a(Peatio::Transaction))
  # end
  # end

  # context 'Spread deposit with two entry' do

  # let(:spread_deposit) do
  # [Peatio::Transaction.new(to_address: 'fake-hot',
  # amount: '2.0',
  # currency_id: currency.id),
  # Peatio::Transaction.new(to_address: 'fake-hot',
  # amount: '2.0',
  # currency_id: currency.id)]
  # end

  # let(:transaction) do
  # [{ hash:        '0xfake',
  # to_address:  hot_wallet.address,
  # amount:      deposit.amount,
  # currency_id: currency.id },
  # { hash:        '0xfake1',
  # to_address:  cold_wallet.address,
  # amount:      deposit.amount,
  # currency_id: currency.id }].map { |t| Peatio::Transaction.new(t)}
  # end

  # subject { service.collect_deposit!(deposit, spread_deposit) }

  # before do
  # deposit.member.payment_address(blockchain).update(address: deposit.address)
  # service.adapter.expects(:create_transaction!).with(spread_deposit.first, subtract_fee: true).returns(transaction.first)
  # service.adapter.expects(:create_transaction!).with(spread_deposit.second, subtract_fee: true).returns(transaction.second)
  # end

  # it 'creates two transactions' do
  # expect(subject).to contain_exactly(*transaction)
  # expect(subject).to all(be_a(Peatio::Transaction))
  # end
  # end
  # end

  # context :deposit_collection_fees do
  # let!(:fee_wallet) { create(:wallet, :fake_fee) }
  # let(:amount) { 2 }
  # let(:deposit) { create(:deposit_btc, amount: amount, currency: currency) }
  # let(:fake_wallet_adapter) { FakeWallet.new }
  # let(:service) { WalletService.new(fee_wallet) }
  # let(:spread_deposit) do
  # [Peatio::Transaction.new(to_address: 'fake-cold',
  # amount: '2.0',
  # currency_id: currency.id,
  # options: { external_wallet_id: 1})]
  # end

  # let(:transactions) do
  # [Peatio::Transaction.new( hash:        '0xfake',
  # to_address:  deposit.address,
  # amount:      '0.01',
  # currency_id: currency.id,
  # options: { gas_limit: 21_000, gas_price: 10_000_000_000 })]
  # end

  # subject { service.deposit_collection_fees!(deposit, spread_deposit) }

  # context 'Adapter collect fees for transaction' do
  # before do
  # deposit.update!(spread: spread_deposit.map(&:as_json))
  # service.adapter.expects(:prepare_deposit_collection!).returns(transactions)
  # end

  # it 'returns transaction' do
  # expect(subject).to contain_exactly(*transactions)
  # expect(subject).to all(be_a(Peatio::Transaction))
  # deposit.spread.map { |s| s.key?(:options) }
  # expect(deposit.spread[0].fetch(:options)).to include :external_wallet_id
  # end
  # end

  # context 'Adapter collect fees for erc20 transaction with parent_id configuration' do
  # let(:currency) { Currency.find('trst') }

  # subject { service.deposit_collection_fees!(deposit, spread_deposit) }

  # before do
  # deposit.update!(spread: spread_deposit.map(&:as_json))
  # service.adapter.expects(:prepare_deposit_collection!).returns(transactions)
  # end

  # it 'returns transaction' do
  # expect(subject).to contain_exactly(*transactions)
  # expect(subject).to all(be_a(Peatio::Transaction))
  # deposit.spread.map { |s| s.key?(:options) }
  # end
  # end

  # context "Adapter doesn't perform any actions before collect deposit" do

  # it 'retunrs empty array' do
  # expect(subject.blank?).to be true
  # end
  # end
  # end
end
