# frozen_string_literal: true

describe API::V2::Entities::Member do
  subject { OpenStruct.new API::V2::Entities::Member.represent(member).serializable_hash }

  let(:member) { create(:member, :level_3) }

  it do
    expect(subject.uid).to eq member.uid
    expect(subject.email).to eq member.email
  end
end
