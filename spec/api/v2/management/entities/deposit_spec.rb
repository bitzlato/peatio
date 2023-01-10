# frozen_string_literal: true

describe API::V2::Management::Entities::Deposit do
  context 'fiat' do
    subject { OpenStruct.new described_class.represent(record).serializable_hash }

    let(:record) { create(:deposit_usd, member: create(:member, :barong)) }

    it do
      expect(subject.tid).to eq record.tid
      expect(subject.currency).to eq 'usd'
      expect(subject.uid).to eq record.member.uid
      expect(subject.type).to eq 'fiat'
      expect(subject.amount).to eq record.amount.to_s
      expect(subject.state).to eq record.aasm_state
      expect(subject.created_at).to eq record.created_at.iso8601
      expect(subject.completed_at).to eq record.completed_at&.iso8601
      expect(subject).not_to respond_to(:blockchain_txid)
    end
  end

  context 'coin' do
    subject { OpenStruct.new described_class.represent(record).serializable_hash }

    let(:record) { create(:deposit_btc, member: create(:member, :barong)) }

    it do
      expect(subject.tid).to eq record.tid
      expect(subject.currency).to eq 'btc'
      expect(subject.uid).to eq record.member.uid
      expect(subject.type).to eq 'coin'
      expect(subject.amount).to eq record.amount.to_s
      expect(subject.state).to eq record.aasm_state
      expect(subject.created_at).to eq record.created_at.iso8601
      expect(subject.completed_at).to eq record.completed_at&.iso8601
      expect(subject.blockchain_txid).to eq record.txid
    end
  end
end
