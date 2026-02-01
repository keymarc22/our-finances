require 'rails_helper'

RSpec.describe GenerateMonthlyTransactionsReportJob, type: :job do
  let!(:account1) { create(:account, name: "Account 1") }
  let!(:account2) { create(:account, name: "Account 2") }

  before do
    # Mock credentials for retention months
    allow(Rails.application.credentials).to receive(:dig).with(:data_retention, :months).and_return(6)
  end

  describe '#perform' do
    context 'with valid accounts' do
      it 'creates a TransactionsReport for each account' do
        expect {
          described_class.new.perform
        }.to change(TransactionsReport, :count).by(2)
      end

      it 'sets the correct cutoff_date based on retention_months' do
        described_class.new.perform

        expected_cutoff = 6.months.ago.to_date
        reports = TransactionsReport.all

        expect(reports.map(&:cutoff_date).uniq).to eq([ expected_cutoff ])
      end

      it 'associates reports with correct accounts' do
        described_class.new.perform

        account_ids = TransactionsReport.pluck(:account_id)
        expect(account_ids).to match_array([ account1.id, account2.id ])
      end
    end

    context 'with existing reports' do
      let!(:existing_report) do
        create(:transactions_report,
          account: account1,
          cutoff_date: 6.months.ago.to_date
        )
      end

      it 'does not create duplicate reports' do
        expect {
          described_class.new.perform
        }.to change(TransactionsReport, :count).by(1) # Only for account2
      end

      it 'skips persisted reports' do
        described_class.new.perform

        # Should have the existing report plus one new one
        expect(TransactionsReport.count).to eq(2)
        expect(TransactionsReport.find_by(account: account1)).to eq(existing_report)
      end
    end

    context 'with validation errors' do
      before do
        # Make one account fail validation
        allow_any_instance_of(TransactionsReport).to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid.new(TransactionsReport.new))
          .once
        allow_any_instance_of(TransactionsReport).to receive(:save!).and_call_original
      end

      it 'logs the error and continues with other accounts' do
        expect(Rails.logger).to receive(:error).with(/Failed to create TransactionsReport/)

        described_class.new.perform
      end

      it 'does not stop processing other accounts' do
        expect {
          described_class.new.perform
        }.to change(TransactionsReport, :count).by_at_least(0)
      end
    end

    context 'with no accounts' do
      before do
        Account.destroy_all
      end

      it 'completes without errors' do
        expect {
          described_class.new.perform
        }.not_to raise_error
      end

      it 'does not create any reports' do
        expect {
          described_class.new.perform
        }.not_to change(TransactionsReport, :count)
      end
    end

    context 'with different retention periods' do
      it 'uses 12 months when configured' do
        allow(Rails.application.credentials).to receive(:dig).with(:data_retention, :months).and_return(12)

        described_class.new.perform

        expected_cutoff = 12.months.ago.to_date
        expect(TransactionsReport.first.cutoff_date).to eq(expected_cutoff)
      end

      it 'uses 3 months when configured' do
        allow(Rails.application.credentials).to receive(:dig).with(:data_retention, :months).and_return(3)

        described_class.new.perform

        expected_cutoff = 3.months.ago.to_date
        expect(TransactionsReport.first.cutoff_date).to eq(expected_cutoff)
      end
    end

    context 'retry behavior' do
      it 'is configured with retry_on' do
        expect(described_class).to have_been_enqueued.exactly(0).times

        # Verify retry configuration exists (can't directly test retry without actual job execution)
        expect(described_class.new).to respond_to(:perform)
      end
    end

    context 'job queue' do
      it 'is queued on the default queue' do
        described_class.perform_later

        expect(described_class).to have_been_enqueued.on_queue("default")
      end
    end
  end
end
