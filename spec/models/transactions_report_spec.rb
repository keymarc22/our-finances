require 'rails_helper'

RSpec.describe TransactionsReport, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:money_account) { create(:money_account, account: account, user: user) }
  
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
    it { should belong_to(:account) }
    it { should have_many(:transactions).dependent(:nullify) }
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
    context 'when transactions exist' do
      before do
        create(:expense, 
          account: account, 
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago
        )
      end

      it 'generates a report for transactions before cutoff_date' do
        report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)
        
        expect(report.transactions.count).to eq(1)
      end

      it 'associates transactions with the report' do
        report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)
        transaction = account.transactions.first
        
        expect(transaction.reload.transactions_report_id).to eq(report.id)
      end
    end

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

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to generate TransactionsReport/)
        create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)
      end
    end
  end

  describe '#clean_transactions' do
    let(:report) { create(:transactions_report, account: account) }
    
    before do
      expense1 = create(:expense, account: account, user: user, money_account: money_account, transaction_date: 7.months.ago)
      expense2 = create(:expense, account: account, user: user, money_account: money_account, transaction_date: 7.months.ago)
      expense1.update(transactions_report_id: report.id)
      expense2.update(transactions_report_id: report.id)
    end

    it 'destroys all associated transactions' do
      expect(report.transactions.count).to eq(2)
      
      report.send(:clean_transactions)
      
      expect(report.transactions.count).to eq(0)
    end

    it 'only deletes transactions associated with this report' do
      other_expense = create(:expense, account: account, user: user, money_account: money_account)
      
      initial_count = account.transactions.count
      report.send(:clean_transactions)
      
      expect(account.transactions.count).to eq(initial_count - 2)
      expect(other_expense.reload).to be_present
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'calls generate_report!' do
        expect_any_instance_of(described_class).to receive(:generate_report!)
        create(:transactions_report, account: account)
      end
    end

    describe 'after_commit with file attached' do
      let(:report) { create(:transactions_report, account: account) }

      it 'enqueues SendTransactionsReportJob when file is attached' do
        expect(SendTransactionsReportJob).to receive(:perform_later).with(report.id)
        
        report.file.attach(
          io: StringIO.new("test,data\n1,2"),
          filename: 'report.csv',
          content_type: 'text/csv'
        )
      end

      it 'enqueues TransactionsCutoffJob when file is attached' do
        expect(TransactionsCutoffJob).to receive(:perform_later).with(report.id)
        
        report.file.attach(
          io: StringIO.new("test,data\n1,2"),
          filename: 'report.csv',
          content_type: 'text/csv'
        )
      end
    end

    describe 'completed status callback' do
      let(:report) { create(:transactions_report, :with_file, account: account, status: :in_process) }
      
      before do
        expense = create(:expense, account: account, user: user, money_account: money_account)
        expense.update(transactions_report_id: report.id)
      end

      it 'calls clean_transactions when status changes to completed' do
        expect(report.transactions.count).to eq(1)
        
        report.update(status: :completed)
        report.reload
        
        expect(report.transactions.count).to eq(0)
      end
    end
  end

  describe 'edge cases' do
    it 'handles transactions with nil money_account gracefully' do
      # This test ensures the system doesn't break with edge data
      incoming = create(:incoming, 
        account: account, 
        user: user,
        money_account: money_account,
        transaction_date: 7.months.ago
      )
      
      report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)
      
      expect(report.transactions).to include(incoming)
    end

    it 'processes large number of transactions efficiently' do
      # Create 100 old transactions
      100.times do
        create(:expense, 
          account: account, 
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago
        )
      end
      
      report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)
      
      expect(report.transactions.count).to eq(100)
    end

    it 'does not include transactions on or after cutoff_date' do
      old_expense = create(:expense, 
        account: account, 
        user: user,
        money_account: money_account,
        transaction_date: 7.months.ago
      )
      
      recent_expense = create(:expense, 
        account: account, 
        user: user,
        money_account: money_account,
        transaction_date: 5.months.ago
      )
      
      report = create(:transactions_report, account: account, cutoff_date: 6.months.ago.to_date)
      
      expect(report.transactions).to include(old_expense)
      expect(report.transactions).not_to include(recent_expense)
    end
  end
end
