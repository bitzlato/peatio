# frozen_string_literal: true

describe API::V2::Management::Entities::Operation do
  Operations::Account::PLATFORM_TYPES.each do |op_type|
    context op_type do
      subject { OpenStruct.new API::V2::Management::Entities::Operation.represent(record).serializable_hash }

      let(:record) { create(op_type) }

      it do
        expect(subject.code).to eq record.code
        expect(subject.currency).to eq record.currency_id
        expect(subject.created_at).to eq record.created_at.iso8601
      end

      context 'credit' do
        it do
          expect(subject.credit).to eq record.credit
          expect(subject).not_to respond_to(:debit)
        end
      end

      context 'debit' do
        let(:record) { create(:asset, :debit) }

        it do
          expect(subject.debit).to eq record.debit
          expect(subject).not_to respond_to(:credit)
        end
      end
    end
  end

  Operations::Account::MEMBER_TYPES.each do |op_type|
    context op_type do
      subject { OpenStruct.new API::V2::Management::Entities::Operation.represent(record).serializable_hash }

      let(:record) { create(op_type, :with_member) }

      it do
        expect(subject.code).to eq record.code
        expect(subject.currency).to eq record.currency_id
        expect(subject.uid).to eq record.member.uid
        expect(subject.created_at).to eq record.created_at.iso8601
      end

      context 'credit' do
        it do
          expect(subject.credit).to eq record.credit
          expect(subject).not_to respond_to(:debit)
        end
      end

      context 'debit' do
        let(:record) { create(:asset, :debit) }

        it do
          expect(subject.debit).to eq record.debit
          expect(subject).not_to respond_to(:credit)
        end
      end
    end
  end
end
