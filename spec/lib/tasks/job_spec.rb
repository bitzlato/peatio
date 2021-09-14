# frozen_string_literal: true

describe 'job.rake' do
  context "Rake::Task['job:liabilities:compact_orders']" do
    subject { Rake::Task['job:liabilities:compact_orders'] }

    let(:member1) { create(:member) }
    let(:member2) { create(:member) }
    let(:job) { Job.last }
    let!(:liabilities) do
      (0..9).to_a.reverse.each do |day|
        create_list(:liability, 100, member_id: [member1.id, member2.id].sample, created_at: Time.now - day.day, updated_at: Time.now - day.day)
      end
    end

    before { DatabaseCleaner.clean }

    after do
      DatabaseCleaner.strategy = :truncation
      subject.reenable
    end

    it 'call rake task with default time range', clean_database_with_truncation: true do
      # default values
      min = (Time.now - 1.week).beginning_of_day.to_s(:db)
      max = (Time.now - 6.days).beginning_of_day.to_s(:db)

      counter = Operations::Liability.where("LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN '#{min}' AND '#{max}'").count
      result = ActiveRecord::Base.connection.query("SELECT NULL, code, currency_id, member_id, SUM(debit), SUM(credit) FROM liabilities WHERE (LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN '#{min}' AND '#{max}') GROUP BY code, member_id, currency_id, DATE(created_at)")
      subject.invoke
      expect(job.error_message).to be_blank
      expect(job.name).to eq('compact_orders')
      expect(job.counter).to eq(counter)
      expect(job.error_code).to eq(0)
      expect(Operations::Liability.where(reference_type: 'CompactOrders').count).to eq(result.count)
    end

    it 'call rake task with time range', clean_database_with_truncation: true do
      min = (Time.now - 2.days).beginning_of_day.to_s(:db)
      max = (Time.now - 1.day).beginning_of_day.to_s(:db)

      counter = Operations::Liability.where("LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN '#{min}' AND '#{max}'").count
      result = ActiveRecord::Base.connection.query("SELECT NULL, code, currency_id, member_id, SUM(debit), SUM(credit) FROM liabilities WHERE (LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN '#{min}' AND '#{max}') GROUP BY code, member_id, currency_id, DATE(created_at)")
      subject.invoke(min, max)
      expect(job.error_message).to be_blank
      expect(job.name).to eq('compact_orders')
      expect(job.counter).to eq(counter)
      expect(job.error_code).to eq(0)
      expect(Operations::Liability.where(reference_type: 'CompactOrders').count).to eq(result.count)
    end
  end
end
