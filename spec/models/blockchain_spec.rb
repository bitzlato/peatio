# frozen_string_literal: true

describe Blockchain do
  context 'validations' do
    subject { build(:blockchain, 'eth-rinkeby') }

    it 'checks valid record' do
      expect(subject).to be_valid
    end

    it 'validates presence of key' do
      subject.key = nil
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Key can't be blank"]
    end

    it 'validates presence of name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Name can't be blank"]
    end

    it 'validates inclusion of status' do
      subject.status = 'abc'
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ['Status is not included in the list']
    end

    it 'validates height should be greater than or equal to 1' do
      subject.height = 0
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ['Height must be greater than or equal to 1']
    end

    it 'validates min_confirmations should be greater than or equal to 1' do
      subject.min_confirmations = 0
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ['Min confirmations must be greater than or equal to 1']
    end

    it 'validates structure of server' do
      subject.server = 'Wrong URL'
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ['Server is not a valid URL']
    end

    it 'saves server in encrypted column' do
      subject.save
      expect do
        subject.server = 'http://parity:8545/'
        subject.save
      end.to change(subject, :server_encrypted)
    end

    it 'does not update server_encrypted before model is saved' do
      subject.save
      expect do
        subject.server = 'http://geth:8545/'
      end.not_to change(subject, :server_encrypted)
    end

    it 'updates server field' do
      expect do
        subject.server = 'http://geth:8545/'
      end.to change(subject, :server).to 'http://geth:8545/'
    end
  end
end
