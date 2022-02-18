# frozen_string_literal: true

class FakeBlockchain < Peatio::Blockchain::Abstract
  def initialize
    @features = { cash_addr_format: false, case_sensitive: true }
  end

  def configure(settings = {}); end
end

RSpec::Matchers.define_negated_matcher :not_change, :change

describe BlockchainService do
  subject(:service) { described_class.new(blockchain) }

  let!(:blockchain) { find_or_create(:blockchain, key: 'eth-rinkeby') }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  context 'when user withdraws to deposit address' do
    let(:account_balance) { 1000 }
    let(:withdraw_amount) { 100 }
    let(:txid) { '0xa2a4414587ad1cbdb2fd0867f0a369562233d043da77f2cd5e0ac7fea4344aaa' }
    let(:currency) { create(:currency, 'usdt') }
    let!(:member) { create(:member) }
    let!(:account) { create(:account, currency: currency, member: member, balance: account_balance, locked: withdraw_amount) }
    let(:blockchain_currency) { create(:blockchain_currency, blockchain: blockchain, currency: currency) }
    let!(:withdraw) { create(:eth_withdraw, aasm_state: :confirming, blockchain: blockchain_currency.blockchain, currency: blockchain_currency.currency, member: member, sum: withdraw_amount, txid: txid) }
    let!(:payment_address) { create(:payment_address, address: '0x4711269d9c58a81b8dab9f7b847a9fca59cfbbbb', blockchain: blockchain, member: member) }
    let!(:wallet) { create(:wallet, address: '0x7075bbbd9bd338ce47a0e7ad23170d94c772aaaa', blockchain: blockchain, kind: :hot) }

    it 'transits withdrawal to succeed and creates deposit' do
      block_number = 0
      create(:currency_wallet, currency: currency, wallet: wallet)

      stub_latest_block_number(id: 1, block_number: block_number + blockchain.min_confirmations)
      EthereumGateway.any_instance.expects(:fetch_block_transactions).returns(
        [Peatio::Transaction.new(amount: blockchain_currency.money_currency.to_money_from_decimal(withdraw_amount.to_d),
                                 block_number: block_number,
                                 blockchain_id: blockchain.id,
                                 currency_id: currency.id,
                                 from: 'wallet',
                                 from_address: wallet.address,
                                 status: 'success',
                                 to: 'deposit',
                                 to_address: payment_address.address,
                                 hash: txid)]
      )

      service.process_block(block_number)

      expect(withdraw.reload.aasm_state).to eq 'succeed'
      expect(member.deposits.take).to have_attributes(currency_id: currency.id, amount: withdraw_amount, txid: txid, aasm_state: 'accepted', address: payment_address.address, from_addresses: [wallet.address], blockchain_id: blockchain.id)
      expect(account.reload).to have_attributes(balance: account_balance + withdraw_amount, locked: 0)
    end
  end

  describe '#process_block' do
    let(:block_number) { 1 }
    let(:account_balance) { 0 }
    let(:txid) { '0xa2a4414587ad1cbdb2fd0867f0a369562233d043da77f2cd5e0ac7fea4344aaa' }
    let!(:currency) { create(:currency, 'usdt') }
    let!(:member) { create(:member) }
    let!(:account) { create(:account, currency: currency, member: member, balance: account_balance) }
    let(:blockchain_currency) { create(:blockchain_currency, blockchain: blockchain, currency: currency,  blockchain: blockchain, min_deposit_amount: 100) }
    let!(:payment_address) { create(:payment_address, address: '0x4711269d9c58a81b8dab9f7b847a9fca59cfbbbb', blockchain: blockchain, member: member) }
    let!(:existed_skipped_deposit) do
      create(:deposit, :deposit_eth, aasm_state: :skipped, blockchain: blockchain, currency: currency, member: member, amount: 10, error: 'Skipped deposit')
    end
    let(:skipped_deposit) do
      blockchain_currency = find_or_create(:blockchain_currency, blockchain: blockchain, currency: currency)
      Peatio::Transaction.new({

                                amount: blockchain_currency.money_currency.to_money_from_decimal(95.to_d),
                                block_number: block_number,
                                blockchain_id: blockchain.id,
                                currency_id: currency.id,
                                from: 'unknown',
                                from_address: '0x7075bbbd9bd338ce47a0e7ad23170d94c772aaab',
                                status: 'success',
                                to: 'deposit',
                                to_address: payment_address.address,
                                hash: '0xa2a4414587ad1cbdb2fd0867f0a369562233d043da77f2cd5e0ac7fea4344aaa'
                              })
    end

    it 'accept new deposit and old skipped deposits' do
      stub_latest_block_number(id: 1, block_number: block_number + blockchain.min_confirmations)
      EthereumGateway.any_instance.expects(:fetch_block_transactions).returns([skipped_deposit])

      expect do
        service.process_block(block_number)
      end.to change { existed_skipped_deposit.reload.aasm_state }.to('accepted').and \
        change(Deposit, :count).by(1).and \
          change { account.reload.balance }.from(0).to(95 + 10)
    end

    it 'skip new deposit and leave skipped old deposits when no volume on balance' do
      blockchain_currency.update min_deposit_amount: 200
      stub_latest_block_number(id: 1, block_number: block_number + blockchain.min_confirmations)
      EthereumGateway.any_instance.expects(:fetch_block_transactions).returns([skipped_deposit])

      expect do
        service.process_block(block_number)
      end.to not_change { existed_skipped_deposit.reload.aasm_state }.and \
        not_change { account.reload.balance }.and \
          change(Deposit, :count).by(1)
    end
  end

  # let!(:blockchain) { create(:blockchain, 'fake-testnet') }
  # let(:block_number) { 100 }
  # let(:fake_adapter) { FakeBlockchain.new }
  # let(:service) { BlockchainService.new(blockchain) }

  # let!(:fake_currency) { create(:currency, :fake, blockchain: blockchain) }
  # let!(:fake_currency1) { create(:currency, :fake, id: 'fake1', blockchain: blockchain) }
  # let!(:fake_currency2) { create(:currency, :fake, id: 'fake2', blockchain: blockchain) }
  # let!(:wallet) { create(:wallet, :fake_deposit) }
  # let!(:member) { create(:member) }
  # let(:transaction) do
  # Peatio::Transaction.new(hash: 'fake_txid',
  # to_address: 'fake_address',
  # from_addresses: ['fake_address'],
  # amount: 5.to_money(fake_currency),
  # block_number: 3,
  # currency_id: 'fake1',
  # txout: 4,
  # status: 'success')
  # end

  # let(:expected_transactions) do
  # [
  # { hash: 'fake_hash1', to_address: 'fake_address', amount: 1.to_money(:fake), block_number: 2, currency_id: 'fake1', txout: 1, from_addresses: ['fake_address'], status: 'success' },
  # { hash: 'fake_hash2', to_address: 'fake_address1', amount: 2.to_money(:fake), block_number: 2, currency_id: 'fake1', txout: 2, from_addresses: ['fake_address'], status: 'success' },
  # { hash: 'fake_hash3', to_address: 'fake_address2', amount: 3.to_money(:fake), block_number: 2, currency_id: 'fake2', txout: 3, from_addresses: ['fake_address'], status: 'success' }
  # ].map { |t| Peatio::Transaction.new(t) }
  # end

  # let(:expected_block) { Peatio::Block.new(block_number, expected_transactions) }

  # before do
  # wallet.currencies << [fake_currency1, fake_currency2]
  # service.stubs(:latest_block_number).returns(4)
  ## service.gateway.class.any_instance.expects(:latest_block_number).never
  # end

  ## Deposit context: (mock fetch_block_transactions)
  ##   * Single deposit in block which should be saved.
  ##   * Multiple deposits in single block (one saved one updated).
  ##   * Multiple deposits for 2 currencies in single block.
  ##   * Multiple deposits in single transaction (different txout).
  # describe 'Filter Deposits' do

  # context 'single fake deposit was created during block processing' do

  # before do
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address')
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # subject { Deposits::Coin.where(currency: fake_currency1) }

  # it { expect(subject.exists?).to be true }

  # context 'creates deposit with correct attributes' do
  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(Peatio::Block.new(block_number, [transaction]))
  # service.process_block(block_number)
  # end

  # it { expect(subject.where(txid: transaction.hash,
  # amount: transaction.amount,
  # address: transaction.to_address,
  # block_number: transaction.block_number,
  # txout: transaction.txout,
  # from_addresses: transaction.from_addresses).exists?).to be true }
  # end

  # #context 'collect deposit after processing block' do
  # #before do
  # #service.stubs(:latest_block_number).returns(100)
  # #service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # #AMQP::Queue.expects(:enqueue).with(:events_processor, is_a(Hash))
  # #end

  # #fi { service.process_block(block_number) }
  # #end

  # context 'process data one more time' do
  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # end

  # it { expect { service.process_block(block_number) }.not_to change { subject } }
  # end
  # end

  # context 'two fake deposits for one currency were created during block processing' do
  # before do
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address')
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address1')
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # subject { Deposits::Coin.where(currency: fake_currency1) }

  # it { expect(subject.count).to eq 2 }

  # context 'one deposit was updated' do
  # let!(:deposit) do
  # Deposit.create!(currency: fake_currency1,
  # member: member,
  # amount: 5,
  # address: 'fake_address',
  # txid: 'fake_txid',
  # block_number: 0,
  # txout: 4,
  # type: Deposits::Coin)
  # end
  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(Peatio::Block.new(block_number, [transaction]))
  # service.process_block(block_number)
  # end
  # it { expect(Deposits::Coin.find_by(txid: transaction.hash).block_number).to eq(transaction.block_number) }
  # end
  # end

  # context 'two fake deposits for two currency were created during block processing' do
  # before do
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address')
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address2')
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # subject { Deposits::Coin.where(currency: [fake_currency1, fake_currency2]) }

  # it do
  # expect(subject.count).to eq 2
  # expect(Deposits::Coin.where(currency: fake_currency1).exists?).to be true
  # expect(Deposits::Coin.where(currency: fake_currency2).exists?).to be true
  # end
  # end

  # context 'skip deposit collection fee transaction' do
  # let!(:transaction) { create(:transaction, txid: 'fake_hash1') }
  # before do
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address')
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # subject { Deposits::Coin.where(currency: [fake_currency1, fake_currency2]) }

  # it do
  # expect(subject.count).to eq 1
  # end
  # end
  # end

  ## Withdraw context: (mock fetch_block_transactions)
  ##   * Single withdrawal.
  ##   * Multiple withdrawals for single currency.
  ##   * Multiple withdrawals for 2 currencies.
  # describe 'Filter Withdrawals' do

  # context 'single fake withdrawal was updated during block processing' do

  # let!(:fake_account) { member.get_account(:fake1).tap { |ac| ac.update!(balance: 50, locked: 5) } }
  # let!(:withdrawal) do
  # Withdraw.create!(member: member,
  # currency: fake_currency1,
  # amount: 1,
  # txid: 'fake_hash1',
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end

  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # it { expect(withdrawal.reload.block_number).to eq(expected_transactions.first.block_number) }

  # context 'single withdrawal was succeed during block processing' do

  # before do
  # service.stubs(:latest_block_number).returns(100)
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # it { expect(withdrawal.reload.succeed?).to be true }
  # end
  # end
  # end

  # context 'two fake withdrawals were updated during block processing' do

  # let!(:fake_account1) { member.get_account(:fake1).tap { |ac| ac.update!(balance: 50, locked: 10) } }
  # let!(:withdrawals) do
  # %w[fake_hash1 fake_hash2].each do |t|
  # Withdraw.create!(member: member,
  # currency: fake_currency1,
  # amount: 1,
  # txid: t,
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end
  # end

  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # subject { Withdraws::Coin.where(currency: fake_currency1) }

  # it do
  # expect(subject.find_by(txid: expected_transactions.first.hash).block_number).to eq(expected_transactions.first.block_number)
  # expect(subject.find_by(txid: expected_transactions.second.hash).block_number).to eq(expected_transactions.second.block_number)
  # end
  # end

  # context 'two fake withdrawals for two currency were updated during block processing' do
  # let!(:fake_account1) { member.get_account(:fake1).tap { |ac| ac.update!(balance: 50, locked: 10) } }
  # let!(:fake_account2) { member.get_account(:fake2).tap { |ac| ac.update!(balance: 50, locked: 10) } }
  # let!(:withdrawal1) do
  # Withdraw.create!(member: member,
  # currency: fake_currency1,
  # amount: 1,
  # txid: "fake_hash1",
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end
  # let!(:withdrawal2) do
  # Withdraw.create!(member: member,
  # currency: fake_currency2,
  # amount: 1,
  # txid: "fake_hash3",
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end

  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # end

  # subject { Withdraws::Coin.where(currency: [fake_currency1, fake_currency2]) }

  # it do
  # expect(subject.find_by(txid: expected_transactions.first.hash).block_number).to eq(expected_transactions.first.block_number)
  # expect(subject.find_by(txid: expected_transactions.third.hash).block_number).to eq(expected_transactions.third.block_number)
  # end

  # context 'fail withdrawal if transaction has status :fail' do

  # let!(:fake_account1) { member.get_account(:fake1).tap { |ac| ac.update!(balance: 50, locked: 10) } }

  # let!(:withdrawal) do
  # Withdraw.create!(member: member,
  # currency: fake_currency1,
  # amount: 1,
  # txid: "fake_hash",
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end

  # let!(:transaction) do
  # Peatio::Transaction.new(hash: 'fake_hash',
  # from_address: 'from',
  # to_address: 'fake_address',
  # amount: 1,
  # block_number: 3,
  # currency_id: fake_currency1.id,
  # txout: 10,
  # status: 'failed')
  # end

  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(Peatio::Block.new(block_number, [transaction]))
  # service.process_block(block_number)
  # end

  # subject { Withdraws::Coin.find_by(currency: fake_currency1, txid: transaction.hash) }

  # it do
  # expect(subject.failed?).to be true
  # end
  # end

  # context 'fail withdrawal if transaction has status :fail' do

  # let!(:fake_account1) { member.get_account(:fake1).tap { |ac| ac.update!(balance: 50, locked: 10) } }

  # let!(:withdrawal) do
  # Withdraw.create!(member: member,
  # currency: fake_currency1,
  # amount: 1,
  # txid: "fake_hash",
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end

  # let!(:transaction) do
  # Peatio::Transaction.new(hash: 'fake_hash', from_address: 'bbb', to_address: 'fake_address', amount: 1, block_number: 3, currency_id: fake_currency1.id, txout: 10, status: 'pending')
  # end

  # let!(:failed_transaction) do
  # Peatio::Transaction.new(hash: 'fake_hash', from_address: 'aaa', to_address: 'fake_address', amount: 1, block_number: 3, currency_id: fake_currency1.id, txout: 10, status: 'failed')
  # end

  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(Peatio::Block.new(block_number, [transaction]))
  # service.gateway.class.any_instance.expects(:fetch_transaction).with(transaction.hash, transaction.txout).returns(failed_transaction)
  # service.process_block(block_number)
  # end

  # subject { Withdraws::Coin.find_by(currency: fake_currency1, txid: transaction.hash) }

  # it do
  # expect(subject.failed?).to be true
  # end
  # end

  # context 'succeed withdrawal if transaction has status :success' do

  # let!(:fake_account1) { member.get_account(:fake1).tap { |ac| ac.update!(balance: 50, locked: 10) } }

  # let!(:withdrawal) do
  # Withdraw.create!(member: member,
  # currency: fake_currency1,
  # amount: 1,
  # txid: "fake_hash",
  # rid: 'fake_address',
  # sum: 1,
  # type: Withdraws::Coin,
  # aasm_state: :confirming)
  # end

  # let!(:transaction) do
  # Peatio::Transaction.new(hash: 'fake_hash',
  # to_address: 'fake_address',
  # from_addresses: 'from',
  # amount: 1,
  # block_number: 3,
  # currency_id: fake_currency1.id,
  # txout: 10,
  # status: 'pending')
  # end

  # let!(:succeed_transaction) do
  # Peatio::Transaction.new(hash: 'fake_hash',
  # to_address: 'fake_address',
  # from_addresses: 'from',
  # amount: 1,
  # block_number: 3,
  # currency_id: fake_currency1.id,
  # txout: 10,
  # status: 'success')
  # end

  # before do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(Peatio::Block.new(block_number, [transaction]))
  # service.stubs(:latest_block_number).returns(10)
  # service.gateway.class.any_instance.expects(:fetch_transaction).with(transaction.hash, transaction.txout).returns(succeed_transaction)
  # service.process_block(block_number)
  # end

  # subject { Withdraws::Coin.find_by(currency: fake_currency1, txid: transaction.hash) }

  # it do
  # expect(subject.succeed?).to be true
  # end
  # end
  # end

  # describe 'Several blocks' do
  # let(:expected_transactions1) do
  # [
  # { hash: 'fake_hash4', from_address: 'aaa', to_address: 'fake_address4', amount: 1.to_money(:fake), block_number: 3, currency_id: 'fake1', txout: 1, status: 'success' },
  # { hash: 'fake_hash5', from_address: 'bbb', to_address: 'fake_address4', amount: 2.to_money(:fake), block_number: 3, currency_id: 'fake1', txout: 2, status: 'success' },
  # { hash: 'fake_hash6', from_address: 'ccc', to_address: 'fake_address4', amount: 3.to_money(:fake), block_number: 3, currency_id: 'fake2', txout: 1, status: 'success' }
  # ].map { |t| Peatio::Transaction.new(t) }
  # end

  # let(:expected_block1) { Peatio::Block.new(block_number, expected_transactions1) }

  # let!(:fake_account1) { member.get_account(:fake1) }
  # let!(:fake_account2) { member.get_account(:fake2) }

  # before do
  # service.stubs(:latest_block_number).returns(100)
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address')
  # PaymentAddress.create!(member: member,
  # blockchain: blockchain,
  # address: 'fake_address2')
  # end

  # fit 'creates deposits and updates withdrawals' do
  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block)
  # service.process_block(block_number)
  # expect(Deposits::Coin.where(currency: fake_currency1).exists?).to be true
  # expect(Deposits::Coin.where(currency: fake_currency2).exists?).to be true
  # Deposit.find_each { |d| d.dispatch! }

  # [fake_account1, fake_account2].map { |a| a.reload }
  # withdraw1 = Withdraw.create!(member: member, currency: fake_currency1, amount: 1, txid: "fake_hash5",
  # rid: 'fake_address4', sum: 1, type: Withdraws::Coin)
  # withdraw1.accept!
  # withdraw1.process!
  # withdraw1.transfer!
  # withdraw1.dispatch!

  # withdraw2 = Withdraw.create!(member: member, currency: fake_currency2, amount: 3, txid: "fake_hash6",
  # rid: 'fake_address4', sum: 3, type: Withdraws::Coin)
  # withdraw2.accept!
  # withdraw2.process!
  # withdraw2.transfer!
  # withdraw2.dispatch!

  # service.gateway.class.any_instance.expects(:fetch_block_transactions).returns(expected_block1)
  # service.process_block(block_number)
  # expect(withdraw1.reload.succeed?).to be true
  # expect(withdraw2.reload.succeed?).to be true
  # end
  # end
end
