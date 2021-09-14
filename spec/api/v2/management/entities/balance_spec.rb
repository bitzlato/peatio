# frozen_string_literal: true

describe API::V2::Management::Entities::Balance do
  subject { OpenStruct.new API::V2::Management::Entities::Balance.represent(record).serializable_hash }

  let(:member) { create(:member, :barong) }
  let(:record) { member.get_account(:usd) }

  before { record.update!(balance: 1000.85, locked: 330.55) }

  it do
    expect(subject.uid).to eq record.member.uid
    expect(subject.balance).to eq '1000.85'
    expect(subject.locked).to eq '330.55'
  end
end
