require 'rails_helper'

RSpec.describe SendTransactionsReportJob, type: :job do
  let(:account) { create(:account) }
  let(:report) { create(:transactions_report, :with_file, :with_transactions, account:) }
  let(:mailer_double) { double('mailer', deliver_now: true) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe '#perform' do
    before do
      allow(TransactionsReportMailer).to receive(:notify_account_users)
        .with(report.id)
        .and_return(mailer_double)
    end

    context 'with valid report' do
      it 'sends the email via TransactionsReportMailer' do
        expect(TransactionsReportMailer).to receive(:notify_account_users)
          .with(report.id)
          .and_return(mailer_double)

        described_class.new.perform(report.id)
      end

      it 'delivers the email' do
        expect(mailer_double).to receive(:deliver_now)

        described_class.new.perform(report.id)
      end
    end

    context 'when mailer fails' do
      before do
        allow(TransactionsReportMailer).to receive(:notify_account_users)
          .and_raise(StandardError.new("Email delivery failed"))
      end

      it 'raises the error' do
        expect {
          described_class.new.perform(report.id)
        }.to raise_error(StandardError, "Email delivery failed")
      end
    end

    context 'job queue' do
      it 'is queued on the mailers queue' do
        described_class.perform_later(report.id)

        expect(described_class).to have_been_enqueued.on_queue("mailers")
      end
    end
  end
end
