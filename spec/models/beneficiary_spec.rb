# frozen_string_literal: true

# TODO: AASM tests.
# TODO: Event API tests.

describe Beneficiary, 'Relationships' do
  context 'beneficiary build by factory' do
    subject { build(:beneficiary) }

    it { expect(subject).to be_valid }
  end

  context 'belongs to member' do
    context 'null member_id' do
      subject { build(:beneficiary, member: nil) }

      it { expect(subject).not_to be_valid }
    end
  end
end

describe Beneficiary, 'Validations' do
  context 'pin presence' do
    context 'nil pin' do
      subject { build(:beneficiary) }

      before { described_class.expects(:generate_pin).returns(nil) }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'pin numericality only_integer' do
    context 'float pin' do
      subject { build(:beneficiary) }

      before { described_class.expects(:generate_pin).returns(3.14) }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'state inclusion' do
    context 'wrong state' do
      subject { build(:beneficiary, state: :wrong) }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'data presence' do
    context 'nil data' do
      subject { build(:beneficiary, data: nil) }

      it { expect(subject).not_to be_valid }
    end

    context 'empty hash data' do
      subject { build(:beneficiary, data: {}) }

      it { expect(subject).not_to be_valid }
    end
  end

  context 'data address presence' do
    context 'fiat' do
      context 'blank address' do
        subject { build(:beneficiary, blockchain_currency: blockchain_currency).tap { |b| b.data.delete('address') } }

        let(:blockchain_currency) { BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'dummy'), currency_id: :usd) }

        it { expect(subject).to be_valid }
      end
    end

    context 'coin' do
      context 'blank address' do
        subject { build(:beneficiary, blockchain_currency: blockchain_currency).tap { |b| b.data.delete(:address) } }

        let(:blockchain_currency) { BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'btc-testnet'), currency_id: :btc) }

        it do
          expect(subject).not_to be_valid
        end
      end
    end
  end

  context 'data full_name presence' do
    # TODO: Write me.
  end
end

describe Beneficiary, 'Callback' do
  context 'before_validation on create' do
    subject { build(:beneficiary) }

    it 'generates pin' do
      expect(subject.pin).to be_nil
      subject.validate!
      expect(subject.pin).not_to be_nil
      pin = subject.pin
      subject.validate!
      expect(subject.pin).to eq(pin)
    end
  end

  context 'before_create' do
    subject { build(:beneficiary) }

    it 'generates sent_at' do
      Timecop.freeze do
        expect(subject.sent_at).to be_nil
        subject.save!
        expect(subject.sent_at).not_to be_nil
        expect(subject.sent_at).to eq(subject.created_at)
      end
    end
  end
end

describe Beneficiary, 'Instance Methods' do
  context 'rid' do
    context 'fiat' do
      subject do
        blockchain_currency = BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'dummy'), currency_id: :usd)
        create(:beneficiary,
               blockchain_currency: blockchain_currency,
               data: generate(:fiat_beneficiary_data).merge(full_name: full_name))
      end

      let(:full_name) { Faker::Name.name_with_middle }

      it do
        expect(subject.rid).to include(*full_name.downcase.split)
        expect(subject.rid).to include(subject.id.to_s)
        expect(subject.rid).to include(subject.currency_id)
      end
    end

    context 'coin' do
      subject do
        blockchain_currency = BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'btc-testnet'), currency_id: :btc)
        create(:beneficiary,
               blockchain_currency: blockchain_currency,
               data: generate(:btc_beneficiary_data).merge(address: address))
      end

      let(:address) { Faker::Blockchain::Bitcoin.address }

      it do
        expect(subject.rid).to include(address)
      end
    end

    context 'masked fields' do
      context 'account number' do
        context 'fiat beneficiary' do
          let!(:fiat_beneficiary) do
            blockchain_currency = BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'dummy'), currency_id: :usd)
            create(:beneficiary, blockchain_currency: blockchain_currency,
                                 data: {
                                   full_name: Faker::Name.name_with_middle,
                                   address: Faker::Address.full_address,
                                   country: Faker::Address.country,
                                   account_number: '0399261557'
                                 })
          end

          it { expect(fiat_beneficiary.masked_account_number).to eq '03****1557' }
        end

        context 'coin beneficiary' do
          let!(:coin_beneficiary) do
            blockchain_currency = BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'btc-testnet'), currency_id: :btc)
            create(:beneficiary, blockchain_currency: blockchain_currency)
          end

          it { expect(coin_beneficiary.masked_account_number).to eq nil }
        end
      end

      context 'masked data' do
        context 'fiat beneficiary' do
          let!(:fiat_beneficiary) do
            blockchain_currency = BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'dummy'), currency_id: :usd)
            create(:beneficiary, blockchain_currency: blockchain_currency,
                                 data: {
                                   full_name: 'Full name',
                                   address: 'Address',
                                   country: 'Country',
                                   account_number: '0399261557'
                                 })
          end

          it 'masks account number' do
            expect(fiat_beneficiary.masked_data).to match({
                                                            full_name: 'Full name',
                                                            address: 'Address',
                                                            country: 'Country',
                                                            account_number: '03****1557'
                                                          })
          end
        end

        context 'coin beneficiary' do
          let!(:coin_beneficiary) do
            blockchain_currency = BlockchainCurrency.find_by!(blockchain: Blockchain.find_by!(key: 'btc-testnet'), currency_id: :btc)
            create(:beneficiary, blockchain_currency: blockchain_currency)
          end

          it 'data shouldnt change' do
            expect(coin_beneficiary.masked_data).to match(coin_beneficiary.data)
          end
        end
      end
    end
  end

  context 'regenerate pin' do
    subject { create(:beneficiary) }

    it do
      sent_at = subject.sent_at
      pin = subject.pin

      Time.stubs(:now).returns(Time.mktime(1970, 1, 1))
      subject.regenerate_pin!
      expect(subject.pin).not_to eq(pin)
      expect(subject.sent_at).not_to eq(sent_at)
    end
  end
end
