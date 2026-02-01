require 'rails_helper'

RSpec.describe SendTransactionsReportJob, type: :job do
  let(:account) { create(:account) }
  let(:report) { create(:transactions_report, :with_file, account: account) }
  let(:mailer_double) { double('mailer', deliver_now: true) }

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

    context 'after_perform callback' do
      it 'updates email_sent flag to true' do
        described_class.new.perform(report.id)

        expect(report.reload.email_sent).to be true
      end

      it 'sets email_sent_at timestamp' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        described_class.new.perform(report.id)

        expect(report.reload.email_sent_at).to be_within(1.second).of(freeze_time)
      end
    end

    context 'with non-existent report' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.new.perform(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
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

      it 'does not update email_sent flag when delivery fails' do
        expect {
          described_class.new.perform(report.id)
        }.to raise_error(StandardError)

        expect(report.reload.email_sent).to be_nil
      end
    end

    context 'job queue' do
      it 'is queued on the mailers queue' do
        described_class.perform_later(report.id)

        expect(described_class).to have_been_enqueued.on_queue("mailers")
      end
    end

    context 'multiple reports' do
      let(:account2) { create(:account) }
      let(:report2) { create(:transactions_report, :with_file, account: account2) }

      before do
        allow(TransactionsReportMailer).to receive(:notify_account_users)
          .and_return(mailer_double)
      end

      it 'sends emails for each report independently' do
        expect(TransactionsReportMailer).to receive(:notify_account_users)
          .with(report.id)
          .and_return(mailer_double)
        expect(TransactionsReportMailer).to receive(:notify_account_users)
          .with(report2.id)
          .and_return(mailer_double)

        described_class.new.perform(report.id)
        described_class.new.perform(report2.id)
      end

      it 'updates each report independently' do
        described_class.new.perform(report.id)
        described_class.new.perform(report2.id)

        expect(report.reload.email_sent).to be true
        expect(report2.reload.email_sent).to be true
      end
    end
  end
end
