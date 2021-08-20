# encoding: UTF-8
# frozen_string_literal: true

describe Withdrawer do
  let(:member) { create(:member, :barong) }
  let(:withdraw) { create(:btc_withdraw, :with_deposit_liability).tap(&:accept!).tap(&:process!) }
  let(:wallet) { find_or_create :wallet, :btc_hot, name: 'Bitcoin Hot Wallet' }
  let(:gateway) { wallet.blockchain.gateway }

  subject { described_class.new(wallet) }

  context do
    before do
      gateway.class.any_instance.expects(:create_transaction!).returns(transaction)
    end

    context 'errored' do
      let(:transaction) { nil}
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
                                hash: SecureRandom.hex(5))
      end
      it do
        subject.call(withdraw)
        expect(withdraw.aasm_state).to eq 'confirming'
      end
    end
  end

  context 'withdrawal with empty rid' do
    before do
      # withdrawal.submit!
      # withdrawal.accept!
      # withdrawal.process!
      #
      # Withdraws::Coin.any_instance
      #                .expects(:rid)
      #                .with(anything)
      #                .twice
      #                .returns('')

    end

    # TODO: Finalize me.
    it 'returns nil and fail withdrawal' do
      # expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be(nil)
      # expect(processing_withdrawal.reload.failed?).to be_truthy
    end
  end

  #context 'hot wallet does not exist' do
    #before do
      #Wallet.expects(:active)
            #.returns(Wallet.none)
    #end

    #it 'returns nil and skip withdrawal' do
      #expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be(nil)
      #expect(processing_withdrawal.reload.skipped?).to be_truthy
    #end
  #end

  #context 'WalletService2 raises error' do
    #before do
      #WalletService.any_instance.expects(:load_balance!)
                   #.returns(100)
      #WalletService.any_instance.expects(:build_withdrawal!)
                   #.raises(Peatio::Wallet::Registry::NotRegisteredAdapterError)
    #end

    #it 'returns true and marks withdrawal as errored' do
      #expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be_truthy
      #expect(processing_withdrawal.reload.errored?).to be_truthy
    #end
  #end

  #context 'wallet balance is not sufficient' do
    #before do
      #WalletService.any_instance
                   #.expects(:load_balance!)
                   #.returns(withdrawal.amount * 0.9)
    #end

    #it 'returns nil and skip withdrawal' do
      #expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be(true)
      #expect(processing_withdrawal.reload.skipped?).to be_truthy
    #end
  #end

  #context 'wallet balance is sufficient but build_withdrawal! raises error' do
    #before do
      #WalletService.any_instance
                   #.expects(:load_balance!)
                   #.returns(withdrawal.amount)

      #WalletService.any_instance
                   #.expects(:build_withdrawal!)
                   #.with(instance_of(Withdraws::Coin))
                   #.raises(Peatio::Blockchain::ClientError)
    #end

    #it 'returns true and marks withdrawal as errored' do
      #expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be_truthy
      #expect(processing_withdrawal.reload.errored?).to be_truthy
    #end
  #end

  #context 'wallet balance is sufficient and build_withdrawal! returns transaction' do
    #before do
      #WalletService.any_instance
                   #.expects(:load_balance!)
                   #.returns(withdrawal.amount)

      #transaction = Peatio::Transaction.new(amount: withdrawal.amount,
                                            #to_address: withdrawal.rid,
                                            #hash: 'hash-1')
      #WalletService.any_instance
                   #.expects(:build_withdrawal!)
                   #.with(instance_of(Withdraws::Coin))
                   #.returns(transaction)
    #end

    #it 'returns true and dispatch withdrawal' do
      #expect(Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)).to be_truthy
      #expect(processing_withdrawal.reload.confirming?).to be_truthy
      #expect(processing_withdrawal.txid).to eq('hash-1')
    #end
  #end

  #context 'transaction with remote_id field' do
    #before do
      #WalletService.any_instance
                   #.expects(:load_balance!)
                   #.returns(withdrawal.amount)

      #transaction = Peatio::Transaction.new(amount: withdrawal.amount,
                                            #to_address: withdrawal.rid,
                                            #options: {
                                              #'remote_id': 'd12331-12312d-34234'
                                            #}.stringify_keys)

      #WalletService.any_instance
                   #.expects(:build_withdrawal!)
                   #.with(instance_of(Withdraws::Coin))
                   #.returns(transaction)
    #end

    #it 'returns true and dispatch withdrawal' do
      #Workers::AMQP::WithdrawCoin.new.process(processing_withdrawal.as_json)
      #expect(processing_withdrawal.reload.under_review?).to be_truthy
      #expect(processing_withdrawal.remote_id).to eq('d12331-12312d-34234')
    #end
  #end
end
