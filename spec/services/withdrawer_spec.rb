# frozen_string_literal: true

describe Withdrawer do
  subject { described_class.new }

  let(:member) { create(:member, :barong) }
  let(:currency) { create(:currency, :btc_bz) }
  let(:blockchain) { create(:blockchain, 'btc-bz-testnet') }
  let(:withdraw) { create(:btc_bz_withdraw, :with_deposit_liability, currency: currency, blockchain: blockchain).tap(&:accept!).tap(&:process!) }
  let!(:wallet) { create(:wallet, :btc_bz_hot, blockchain: blockchain) }

  before do
    create(:blockchain_currency, blockchain: blockchain, currency: currency)
    BalancesUpdater.any_instance.stubs(:perform)
    Wallet.any_instance.stubs(:can_withdraw_for?).returns(true)
  end

  context do
    before do
      Bitzlato::Wallet.any_instance.expects(:create_transaction!).returns(transaction)
    end

    context 'errored' do
      let(:transaction) { nil }

      it do
        subject.call(withdraw)
        expect(withdraw.aasm_state).to eq 'errored'
      end
    end

    context 'succesful withdraw' do
      let(:transaction) do
        Peatio::Transaction.new(amount: withdraw.money_amount,
                                from_address: wallet.address,
                                to_address: withdraw.to_address,
                                blockchain_id: blockchain.id,
                                from: 'unknown',
                                to: 'deposit',
                                hash: SecureRandom.hex(5))
      end

      it do
        subject.call(withdraw)
        expect(withdraw.aasm_state).to eq 'confirming'
      end
    end
  end

  context 'when insufficient funds error is raised' do
    let(:account) { create(:account, :eth, balance: 100) }
    let(:withdraw) { create(:eth_withdraw, currency: account.currency, blockchain: Blockchain.find_by!(key: 'eth-rinkeby'), member: account.member).tap(&:accept!).tap(&:process!) }
    let(:wallet) { find_or_create :wallet, :eth_hot }

    it 'fails withdraw' do
      EthereumGateway::AbstractCommand.any_instance.expects(:fetch_gas_price).returns(0)
      EthereumGateway::TransactionCreator.any_instance.expects(:call).raises(Ethereum::Client::InsufficientFunds.new('-32010', 'Insufficient funds. The account you tried to send transaction from does not have enough funds.'))

      subject.call(withdraw)
      expect(withdraw.aasm_state).to eq 'failed'
    end
  end

  context 'withdrawal with empty rid' do # TODO: Finalize me.
    it 'returns nil and fail withdrawal' do
      # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be(nil)
      # expect(processing_withdrawal.reload.failed?).to be_truthy
    end
  end

  context 'when low wallet balance' do
    before do
      Wallet.any_instance.stubs(:can_withdraw_for?).returns(false)
    end

    it 'fails withdraw' do
      subject.call(withdraw)
      expect(withdraw.aasm_state).to eq 'errored'
    end
  end

  # context 'hot wallet does not exist' do
  # before do
  # Wallet.expects(:active)
  # .returns(Wallet.none)
  # end

  # it 'returns nil and skip withdrawal' do
  # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be(nil)
  # expect(processing_withdrawal.reload.skipped?).to be_truthy
  # end
  # end

  # context 'WalletService2 raises error' do
  # before do
  # WalletService.any_instance.expects(:load_balance!)
  # .returns(100)
  # WalletService.any_instance.expects(:build_withdrawal!)
  # .raises(Peatio::Wallet::Registry::NotRegisteredAdapterError)
  # end

  # it 'returns true and marks withdrawal as errored' do
  # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be_truthy
  # expect(processing_withdrawal.reload.errored?).to be_truthy
  # end
  # end

  # context 'wallet balance is not sufficient' do
  # before do
  # WalletService.any_instance
  # .expects(:load_balance!)
  # .returns(withdrawal.amount * 0.9)
  # end

  # it 'returns nil and skip withdrawal' do
  # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be(true)
  # expect(processing_withdrawal.reload.skipped?).to be_truthy
  # end
  # end

  # context 'wallet balance is sufficient but build_withdrawal! raises error' do
  # before do
  # WalletService.any_instance
  # .expects(:load_balance!)
  # .returns(withdrawal.amount)

  # WalletService.any_instance
  # .expects(:build_withdrawal!)
  # .with(instance_of(Withdraws::Coin))
  # .raises(Peatio::Blockchain::ClientError)
  # end

  # it 'returns true and marks withdrawal as errored' do
  # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be_truthy
  # expect(processing_withdrawal.reload.errored?).to be_truthy
  # end
  # end

  # context 'wallet balance is sufficient and build_withdrawal! returns transaction' do
  # before do
  # WalletService.any_instance
  # .expects(:load_balance!)
  # .returns(withdrawal.amount)

  # transaction = Peatio::Transaction.new(amount: withdrawal.amount,
  # to_address: withdrawal.rid,
  # hash: 'hash-1')
  # WalletService.any_instance
  # .expects(:build_withdrawal!)
  # .with(instance_of(Withdraws::Coin))
  # .returns(transaction)
  # end

  # it 'returns true and dispatch withdrawal' do
  # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be_truthy
  # expect(processing_withdrawal.reload.confirming?).to be_truthy
  # expect(processing_withdrawal.txid).to eq('hash-1')
  # end
  # end

  # context 'transaction with remote_id field' do
  # before do
  # WalletService.any_instance
  # .expects(:load_balance!)
  # .returns(withdrawal.amount)

  # transaction = Peatio::Transaction.new(amount: withdrawal.amount,
  # to_address: withdrawal.rid,
  # options: {
  # 'remote_id': 'd12331-12312d-34234'
  # }.stringify_keys)

  # WalletService.any_instance
  # .expects(:build_withdrawal!)
  # .with(instance_of(Withdraws::Coin))
  # .returns(transaction)
  # end

  # it 'returns true and dispatch withdrawal' do
  # Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)
  # expect(processing_withdrawal.reload.under_review?).to be_truthy
  # expect(processing_withdrawal.remote_id).to eq('d12331-12312d-34234')
  # end
  # end
end
