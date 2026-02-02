require 'rails_helper'

RSpec.describe TransactionsCutoffJob, type: :job do
  describe '#perform' do
    context 'with valid report_id' do
      let(:report) { create(:transactions_report, :with_file, :with_transactions) }

      it 'performs the job successfully' do
        expect {
          described_class.new.perform(report.id)
        }.not_to raise_error
      end

      it 'marks the report as completed on success' do
        described_class.new.perform(report.id)
        expect(report.reload.status).to eq('completed')
      end

      it 'marks the report as failed on error' do
        report = create(:transactions_report)

        described_class.new.perform(report.id)
        expect(report.reload.status).to eq('failed')
      end

      it 'creates cutoff transactions correctly' do
        money_account = create(:money_account)
        report = create(:transactions_report, :with_file)
        transaction1 = create(:incoming, money_account:, amount_cents: 5000, transactions_report_id: report.id)
        transaction2 = create(:expense, money_account:, amount_cents: -2000, transactions_report_id: report.id)

        described_class.new.perform(report.id)
        cutoff_transaction = money_account.transactions.where(cutoff: true).first
        expect(cutoff_transaction).not_to be_nil
        expect(cutoff_transaction.amount_cents).to eq(3000)
      end
    end

    context 'with invalid report_id' do
      it 'logs error and marks report as failed' do
        expect(Rails.logger).to receive(:error).with(/TransactionsCutoffJob failed for report 99999/)
        described_class.new.perform(99999)
      end
    end
  end
end
