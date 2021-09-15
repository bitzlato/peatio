# frozen_string_literal: true

describe API::V2::Entities::Account do
  subject { OpenStruct.new described_class.represent(account).serializable_hash }

  let(:account) { create(:account, :btc, balance: 100) }

  it do
    expect(subject.currency).to eq 'btc'
    expect(subject.balance).to eq '100.0'
    expect(subject.locked).to eq '0.0'
  end
end
