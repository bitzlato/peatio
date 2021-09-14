# frozen_string_literal: true

describe Currency do
  context 'fiat' do
    let(:currency) { described_class.find(:usd) }

    it 'allows to change deposit fee' do
      currency.update!(deposit_fee: 0.25)
      expect(currency.deposit_fee).to eq 0.25
    end
  end

  context 'coin' do
    let(:currency) { described_class.find(:btc) }

    it 'doesn\'t allow to change deposit fee' do
      currency.update!(deposit_fee: 0.25)
      expect(currency.deposit_fee).to eq 0
    end

    it 'validates position' do
      currency.position = 0
      expect(currency).not_to be_valid
      expect(currency.errors[:position].size).to eq(1)
    end

    it 'validate position value on update' do
      currency.update(position: nil)
      expect(currency.valid?).to eq false
      expect(currency.errors[:position].size).to eq(2)

      currency.update(position: 0)
      expect(currency.valid?).to eq false
      expect(currency.errors[:position].size).to eq(1)
    end
  end

  context 'token' do
    let!(:currency) { described_class.find(:ring) }
    let!(:trst_currency) { described_class.find(:trst) }
    let!(:fiat_currency) { described_class.find(:eur) }

    # coin configuration
    it 'validate parent_id presence' do
      currency.parent_id = nil
      expect(currency.valid?).to eq true
    end

    # token configuration
    it 'validate parent_id value' do
      currency.parent_id = fiat_currency.id
      expect(currency).not_to be_valid
      expect(currency.errors[:parent_id]).to eq ['wrong fiat/crypto nesting']

      currency.parent_id = trst_currency.id
      expect(currency).not_to be_valid
      expect(currency.errors[:parent_id]).to eq ['wrong parent currency']
    end
  end

  context 'scopes' do
    let(:currency) { described_class.find(:btc) }

    context 'visible' do
      it 'changes visible scope count' do
        visible = described_class.visible.count
        currency.update(visible: false)
        expect(described_class.visible.count).to eq(visible - 1)
      end
    end

    context 'deposit_enabled' do
      it 'changes deposit_enabled scope count' do
        deposit_enabled = described_class.deposit_enabled.count
        currency.update(deposit_enabled: false)
        expect(described_class.deposit_enabled.count).to eq(deposit_enabled - 1)
      end
    end

    context 'withdrawal_enabled' do
      it 'changes withdrawal_enabled scope count' do
        withdrawal_enabled = described_class.withdrawal_enabled.count
        currency.update(withdrawal_enabled: false)
        expect(described_class.withdrawal_enabled.count).to eq(withdrawal_enabled - 1)
      end
    end
  end

  context 'read only attributes' do
    let!(:fake_currency) { create(:currency, :btc, id: 'fake') }

    it 'does not update the type' do
      fake_currency.update type: 'fiat'
      expect(fake_currency.reload.type).to eq(fake_currency.type)
    end
  end

  context 'serialization' do
    let!(:currency) { described_class.find(:ring) }

    let(:options) { { 'gas_price' => 'standard', 'erc20_contract_address' => '0x022e292b44b5a146f2e8ee36ff44d3dd863c915c', 'gas_limit' => '100000' } }

    it 'serialize/deserializes options' do
      currency.update(options: options)
      expect(described_class.find(:ring).options).to eq options
    end
  end

  context 'validate max currency' do
    before { ENV['MAX_CURRENCIES'] = '6' }

    after  { ENV['MAX_CURRENCIES'] = nil }

    it 'raises validation error for max currency' do
      record = build(:currency, :fake, id: 'fake2', type: 'fiat')
      record.save
      expect(record.errors.full_messages).to include(/Max Currency limit has been reached/i)
    end
  end

  context 'Methods' do
    context 'token?' do
      let!(:coin) { described_class.find(:btc) }
      let!(:token) { described_class.find(:trst) }

      it { expect(coin.token?).to eq false }
      it { expect(token.token?).to eq true }
    end
  end

  context 'Callbacks' do
    context 'after_create' do
      let!(:coin) { described_class.find(:btc) }

      it 'move to the bottom if there is no position' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        described_class.create(code: 'test', parent_id: coin.id)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3], ['eth', 4],
                                                                         ['trst', 5], ['ring', 6], ['test', 7]]
      end

      it 'move to the bottom of all currencies' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        described_class.create(code: 'test', parent_id: coin.id, position: 7)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3], ['eth', 4],
                                                                         ['trst', 5], ['ring', 6], ['test', 7]]
      end

      it 'move to the bottom when position is greater that currencies count' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        described_class.create(code: 'test', parent_id: coin.id, position: described_class.all.count + 2)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3], ['eth', 4],
                                                                         ['trst', 5], ['ring', 6], ['test', 7]]
      end

      it 'move to the top of all currencies' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        described_class.create!(code: 'test', parent_id: coin.id, position: 1)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['test', 1], ['usd', 2], ['eur', 3], ['btc', 4],
                                                                         ['eth', 5], ['trst', 6], ['ring', 7]]
      end

      it 'move to the middle of all currencies' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        described_class.create(code: 'test', parent_id: coin.id, position: 5)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['test', 5], ['trst', 6], ['ring', 7]]
      end

      it 'position equal to currencies amount' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        described_class.create(code: 'test', parent_id: coin.id, position: 6)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3], ['eth', 4],
                                                                         ['trst', 5], ['test', 6], ['ring', 7]]
      end

      context 'link_wallets' do
        let!(:coin) { described_class.find(:eth) }
        let!(:wallet) { Wallet.deposit_wallets(:eth)[0] }

        context 'without parent id' do
          it 'does not create currency wallet' do
            currency = described_class.create(code: 'test', blockchain: Blockchain.last)
            expect(CurrencyWallet.find_by(currency_id: currency.id, wallet_id: wallet.id)).to eq nil
          end
        end

        context 'with parent id' do
          it 'creates currency wallet' do
            currency = described_class.create(code: 'test', parent_id: coin.id)
            c_w = CurrencyWallet.find_by(currency_id: currency.id, wallet_id: wallet.id)

            expect(c_w.present?).to eq true
            expect(c_w.currency_id).to eq currency.id
          end
        end
      end
    end

    context 'before update' do
      let!(:coin) { described_class.find(:btc) }

      it 'move to the bottom of all currencies' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        coin.update(position: 6)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['eth', 3],
                                                                         ['trst', 4], ['ring', 5], ['btc', 6]]
      end

      it 'move to the bottom when position is greater that currencies count' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        coin.update(position: described_class.all.count + 2)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['eth', 3],
                                                                         ['trst', 4], ['ring', 5], ['btc', 6]]
      end

      it 'move to the top of all currencies' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        coin.update(position: 1)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['btc', 1], ['usd', 2], ['eur', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
      end

      it 'move to the middle of all currencies' do
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['btc', 3],
                                                                         ['eth', 4], ['trst', 5], ['ring', 6]]
        coin.update(position: 4)
        expect(described_class.all.ordered.pluck(:id, :position)).to eq [['usd', 1], ['eur', 2], ['eth', 3],
                                                                         ['btc', 4], ['trst', 5], ['ring', 6]]
      end
    end
  end
end
