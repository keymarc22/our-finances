require 'rails_helper'
require 'stringio'

RSpec.describe TransactionsReport, type: :model do
  let(:account)       { create(:account) }
  let(:user)          { create(:user, account:) }
  let(:money_account) { create(:money_account, account:, user:) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      report = build(:transactions_report, account: account)
      expect(report).to be_valid
    end

    it 'is invalid without account_id' do
      report = build(:transactions_report, account: nil)
      expect(report).not_to be_valid
      expect(report.errors[:account_id]).to be_present
    end

    it 'is invalid without cutoff_date' do
      report = build(:transactions_report, account: account, cutoff_date: nil)
      expect(report).not_to be_valid
      expect(report.errors[:cutoff_date]).to be_present
    end
  end

  describe 'associations' do
    it 'belongs to account' do
      report = build(:transactions_report, account: account)
      expect(report.account).to eq(account)
    end

    it 'has many transactions with dependent nullify' do
      report = create(:transactions_report, account: account)
      expense = create(:expense, account: account, user: user, money_account: money_account)
      expense.update(transactions_report_id: report.id)

      expect(report.transactions).to include(expense)

      report.destroy
      expect(expense.reload.transactions_report_id).to be_nil
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(described_class.statuses.keys).to match_array(%w[in_process completed failed])
    end
  end

  describe 'file attachment' do
    it 'can attach a file' do
      report = create(:transactions_report, :with_file, account: account)
      expect(report.file).to be_attached
    end

    it 'file_attached? returns true when file is attached' do
      report = create(:transactions_report, :with_file, account: account)
      expect(report.file_attached?).to be true
    end

    it 'file_attached? returns false when no file is attached' do
      report = create(:transactions_report, account: account)
      expect(report.file_attached?).to be false
    end
  end

  describe '#generate_report!' do
    context 'when no transactions exist before cutoff date' do
      it 'sets status to failed' do
        report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)

        expect(report.status).to eq('failed')
      end

      it 'does not attach a file' do
        report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)

        expect(report.file).not_to be_attached
      end
    end

    context 'when an error occurs during generation' do
      before do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago
        )
        allow_any_instance_of(TransactionsReportService).to receive(:call).and_raise(StandardError.new("CSV Error"))
      end

      it 'sets status to failed' do
        report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)

        expect(report.status).to eq('failed')
      end
    end
  end
end
