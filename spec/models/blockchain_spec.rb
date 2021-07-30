# encoding: UTF-8
# frozen_string_literal: true

describe Blockchain do
  context 'validations' do

    subject { build(:blockchain, 'eth-mainet') }

    it 'checks valid record' do
      expect(subject).to be_valid
    end

    it 'validates presence of key' do
      subject.key = nil
      subject.scope = 'btc'
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Key can't be blank"]
    end

    it 'validates client' do
      subject.client = 'zephyreum'
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Client is not included in the list"]
    end

    it 'validates presence of name' do
      subject.name = nil
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Name can't be blank"]
    end

    it 'validates presence of client' do
      subject.client = nil
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to include "Client can't be blank"
    end

    it 'validates inclusion of status' do
      subject.status = 'abc'
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Status is not included in the list"]
    end

    it 'validates height should be greater than or equal to 1' do
      subject.height = 0
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Height must be greater than or equal to 1"]
    end

    it 'validates min_confirmations should be greater than or equal to 1' do
      subject.min_confirmations = 0
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Min confirmations must be greater than or equal to 1"]
    end

    it 'validates structure of server' do
      subject.server = 'Wrong URL'
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to eq ["Server is not a valid URL"]
    end
  end
end
