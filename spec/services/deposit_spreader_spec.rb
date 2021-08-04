# encoding: UTF-8
# frozen_string_literal: true

describe DepositSpreader do
  let!(:blockchain) { create(:blockchain, 'fake-testnet') }
  let!(:deposit_wallet) { create(:wallet, :fake_deposit) }
  let!(:currency) { create(:currency, :fake) }
  let(:fake_wallet_adapter) { FakeWallet.new }
  let(:fake_blockchain_adapter) { FakeBlockchain.new }

  before do
    Blockchain.any_instance.stubs(:blockchain_api).returns(BlockchainService.new(blockchain))
  end

  context :spread_between_wallets do
    let(:service) { DepositSpreader.new(nil) }


    # Single wallet:
    #   * Deposit fits exactly.
    #   * Deposit doesn't fit.
    # Two wallets:
    #   * Deposit fits to first wallet.
    #   * Deposit fits to second wallet.
    #   * Partial spread between first and second.
    #   * Deposit doesn't fit to both wallets.
    #   * Negative min_collection_amount.
    # Three wallets:
    #   * Partial spread between first and second.
    #   * Partial spread between first and third.
    #   * Partial spread between first, second and third.
    #   * Deposit doesn't fit to all wallets.

    let(:deposit) { Deposit.new(amount: 1.2, currency_id: :fake) }

    context 'Single wallet' do

      context 'single wallet available' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 8.8,
            max_balance: 10,
            min_collection_amount: 1,
            plain_settings: { external_wallet_id: 1 }}]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: deposit.amount,
             currency_id: currency.id,
             options: { external_wallet_id: 1 } }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to single wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'single wallet available + skip_deposit_collection' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 8.8,
            max_balance: 10,
            min_collection_amount: deposit.amount,
            skip_deposit_collection: true }]
        end

        let(:expected_spread) do
          [{:amount=>"1.2", :currency_id=>"fake", :status=>"skipped", :to_address=>"destination-wallet-1"}]
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'returns spread with skipped transaction' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
        end
      end

      context 'Single wallet is full' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 10,
            max_balance: 10,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: deposit.amount,
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end
    end

    context 'Two wallets' do

      context 'Deposit fits to first wallet' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 5,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 100.0,
            max_balance: 100,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: deposit.amount,
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Deposit fits to second wallet' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 10,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 95,
            max_balance: 100,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-2',
             status: 'pending',
             amount: deposit.amount,
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Partial spread between first and second' do

        let(:deposit) { Deposit.new(amount: 10, currency_id: :fake) }

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 5,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 90,
            max_balance: 100,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: '5.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-2',
             status: 'pending',
             amount: '5.0',
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Two wallets are full' do
        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 10,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 100,
            max_balance: 100,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-2',
             status: 'pending',
             amount: '1.2',
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'different min_collection_amount' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 10,
            max_balance: 10,
            min_collection_amount: 1 },
           { address: 'destination-wallet-2',
            balance: 100,
            max_balance: 100,
            min_collection_amount: 2 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-2',
             status: 'pending',
             amount: '1.2',
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to single wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'tiny min_collection_amount' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
             balance: 10,
             max_balance: 10,
             min_collection_amount: 2 },
           { address: 'destination-wallet-2',
             balance: 100,
             max_balance: 100,
             min_collection_amount: 3 }.as_json].map(&:symbolize_keys)
        end

        let(:expected_spread) { [] }

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to single wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end
    end

    context 'Three wallets' do

      context 'Partial spread between first and second' do

        let(:deposit) { Deposit.new(amount: 10, currency_id: :fake) }

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 5,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 95,
            max_balance: 100,
            min_collection_amount: 1 },
          { address: 'destination-wallet-3',
            balance: 1001.0,
            max_balance: 1000,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: '5.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-2',
             status: 'pending',
             amount: '5.0',
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Partial spread between first and third' do

        let(:deposit) { Deposit.new(amount: 10, currency_id: :fake) }

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 5,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 100,
            max_balance: 100,
            min_collection_amount: 1 },
          { address: 'destination-wallet-3',
            balance: 995.0,
            max_balance: 1000,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: '5.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-3',
             status: 'pending',
             amount: '5.0',
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Three wallets are full' do

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 10.1,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 100.0,
            max_balance: 100,
            min_collection_amount: 1 },
          { address: 'destination-wallet-3',
            balance: 1001.0,
            max_balance: 1000,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-3',
             status: 'pending',
             amount: deposit.amount,
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads everything to last wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Partial spread between first, second and third' do

        let(:deposit) { Deposit.new(amount: 10, currency_id: :fake) }

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 7,
            max_balance: 10,
            min_collection_amount: 1 },
          { address: 'destination-wallet-2',
            balance: 97,
            max_balance: 100,
            min_collection_amount: 1 },
          { address: 'destination-wallet-3',
            balance: 995.0,
            max_balance: 1000,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'pending',
             amount: '3.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-2',
             status: 'pending',
             amount: '3.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-3',
             status: 'pending',
             amount: '4.0',
             currency_id: currency.id }.as_json].map(&:symbolize_keys)
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads between wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'Partial spread between first, second and third + skip deposit collection option' do

        let(:deposit) { Deposit.new(amount: 10, currency_id: :fake) }

        let(:destination_wallets) do
          [{ address: 'destination-wallet-1',
            balance: 7,
            max_balance: 10,
            min_collection_amount: 1,
            skip_deposit_collection: true },
          { address: 'destination-wallet-2',
            balance: 97,
            max_balance: 100,
            min_collection_amount: 1 },
          { address: 'destination-wallet-3',
            balance: 995.0,
            max_balance: 1000,
            min_collection_amount: 1 }]
        end

        let(:expected_spread) do
          [{ to_address: 'destination-wallet-1',
             status: 'skipped',
             amount: '3.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-2',
             status: 'pending',
             amount: '3.0',
             currency_id: currency.id },
           { to_address: 'destination-wallet-3',
             status: 'pending',
             amount: '4.0',
             currency_id: currency.id}]
        end

        subject { service.send(:spread_between_wallets, deposit, destination_wallets) }

        it 'spreads between wallet' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end
    end
  end

  context :spread_deposit do
    before do
      Peatio::Blockchain.registry.expects(:[])
                        .with(:bitcoin)
                        .returns(fake_blockchain_adapter.class)
                        .at_least_once
    end

    let!(:deposit_wallet) { create(:wallet, :fake_deposit) }
    let!(:hot_wallet) { create(:wallet, :fake_hot) }
    let!(:cold_wallet) { create(:wallet, :fake_cold) }

    let(:amount) { 2 }
    let(:deposit) { create(:deposit_btc, amount: amount, currency: currency) }

    let(:expected_spread) do
      [{ to_address: 'fake-cold',
         status: 'pending',
         amount: '2.0',
         currency_id: currency.id }]
    end

    subject { DepositSpreader.call(deposit) }

    context 'hot wallet is full and cold wallet balance is not available' do
      before do
        # Hot wallet balance is full and cold wallet balance is not available.
        Wallet.any_instance.stubs(:current_balance).returns(hot_wallet.max_balance, 'N/A')
      end

      it 'spreads everything to cold wallet' do
        expect(Wallet.active_retired.withdraw.joins(:currencies).where(currencies: { id: deposit.currency_id }).count).to eq 2

        expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
        expect(subject).to all(be_a(Peatio::Transaction))
      end
    end

    context 'hot wallet is full, warm and cold wallet balances are not available' do
      let!(:warm_wallet) { create(:wallet, :fake_warm) }
      before do
        # Hot wallet is full, warm and cold wallet balances are not available.
        Wallet.any_instance.stubs(:current_balance).returns(hot_wallet.max_balance, 'N/A', 'N/A')
      end

      it 'skips warm wallet and spreads everything to cold wallet' do
        expect(Wallet.active_retired.withdraw.joins(:currencies).where(currencies: { id: deposit.currency_id }).count).to eq 3

        expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
        expect(subject).to all(be_a(Peatio::Transaction))
      end
    end

    context 'there is no active wallets' do
      before { Wallet.stubs(:active).returns(Wallet.none) }

      it 'raises an error' do
        expect{ subject }.to raise_error(StandardError)
      end
    end

    context 'currency price recalculation' do
      let(:deposit) { create(:deposit_btc, amount: amount, currency: currency) }

      context 'collect to hot wallet' do
        let(:expected_spread) do
          [{ to_address: 'fake-hot',
             status: 'pending',
             amount: deposit.amount.to_s,
             currency_id: currency.id }]
        end

        before do
          # Deposit with amount 2 and currency price 42
          hot_wallet.update!(max_balance: 100)
          deposit.currency.update!(price: 42)
          # Hot wallet balance is empty
          Wallet.any_instance.stubs(:current_balance).with(deposit.currency).returns(0)
          Currency.any_instance.unstub(:price)
        end

        it 'skip hot wallet and collect to cold' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'collect to cold wallet' do
        let(:expected_spread) do
          [{ to_address: 'fake-cold',
             status: 'pending',
             amount: deposit.amount.to_s,
             currency_id: currency.id }]
        end

        before do
          # Hot wallet balance is ful.
          deposit.currency.update!(price: 42)
          Wallet.any_instance.stubs(:current_balance).with(deposit.currency).returns(deposit.amount)
          Currency.any_instance.unstub(:price)
        end

        it 'skip hot wallet and collect to cold' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end

      context 'split to hot and cold wallet' do
        let(:expected_spread) do
          [{ to_address: 'fake-hot',
             status: 'pending',
             amount: '1.38095238',
             currency_id: currency.id },
           { to_address: 'fake-cold',
             status: 'pending',
             amount: '0.61904762',
             currency_id: currency.id }]
        end

        before do
          # Deposit with amount 2 and currency price 42
          hot_wallet.update!(max_balance: 100)
          # Hot wallet balance is full and cold wallet balance is not available.
          deposit.currency.update!(price: 42)
          Wallet.any_instance.stubs(:current_balance).with(deposit.currency).returns(deposit.amount / 2)
          Currency.any_instance.unstub(:price)
        end

        it 'skip hot wallet and collect to cold' do
          expect(subject.map(&:as_json).map(&:symbolize_keys)).to contain_exactly(*expected_spread)
          expect(subject).to all(be_a(Peatio::Transaction))
        end
      end
    end
  end


end
