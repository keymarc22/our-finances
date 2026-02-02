require 'rails_helper'

RSpec.describe 'Transactions Report Full Workflow', type: :integration do
  let(:account)       { create(:account, name: "Test Account") }
  let(:user)          { create(:user, account: account) }
  let(:money_account) { create(:money_account, account: account, user: user, name: "Cash") }
  let(:budget)        { create(:budget, account: account, user: user) }

  before do
    # Mock credentials
    allow(Rails.application.credentials).to receive(:dig).with(:mailer, :default_from).and_return('example@gmail.com')
    allow(Rails.application.credentials).to receive(:dig).with(:data_retention, :months).and_return(6)
  end

  describe 'complete workflow: generate → send → cutoff → clean' do
    context 'with valid transactions' do
      before do
        # (7-9 months ago)
        5.times do |i|
          create(:expense,
            account: account,
            user: user,
            money_account: money_account,
            budget: budget,
            transaction_date: (7 + i).months.ago,
            amount_cents: (1000 * -(i + 1)),
            description: "Old expense #{i + 1}"
          )
        end

        # (should NOT be included)
        3.times do |i|
          create(:expense,
            account: account,
            user: user,
            money_account: money_account,
            budget: budget,
            transaction_date: (2 + i).months.ago,
            amount_cents: 500 * -(i + 1),
            description: "Recent expense #{i + 1}"
          )
        end
      end

      it 'generates report, sends email, creates cutoff, and cleans old transactions' do
        expect {
          GenerateMonthlyTransactionsReportJob.new.perform
        }.to change(TransactionsReport, :count).by(1)

        report = TransactionsReport.last
        expect(report.account).to eq(account)
        expect(report.cutoff_date).to eq(6.months.ago.to_date)
        expect(report.transactions.count).to eq(0)
        expect(report.file).to be_attached
        expect(report.file.filename.to_s).to include('transactions_report')

        # Verify cutoff transaction was created
        cutoff_transaction = Transaction.find_by(cutoff: true)
        expect(cutoff_transaction).to be_present
        expect(cutoff_transaction.description).to eq("Corte de cuenta Cash")
        expect(cutoff_transaction.amount_cents).to eq(-3000)
        expect(cutoff_transaction.type).to eq("Expense")
        expect(report.reload.status).to eq('completed')
      end
    end

    context 'with no old transactions' do
      before do
        # Only create recent transactions
        2.times do |i|
          create(:expense,
            account: account,
            user: user,
            money_account: money_account,
            transaction_date: 10.months.ago,
            amount_cents: -1000,
            description: "Recent expense #{i + 1}"
          )
        end
      end

      it 'marks report as failed and does not send email or create cutoff' do
        GenerateMonthlyTransactionsReportJob.new.perform

        report = TransactionsReport.last
        expect(report.status).to eq('failed')
        expect(report.file).not_to be_attached

        # Should not create any cutoff transactions
        expect(Transaction.where(cutoff: true).count).to eq(0)
      end
    end

    context 'with mixed transaction types' do
      before do
        create(:expense,
          account:,
          user:,
          money_account: money_account,
          transaction_date: 3.months.ago,
          amount_cents: -10000,
          description: "Old expense"
        )

        create(:incoming,
          account:,
          user:,
          money_account: money_account,
          transaction_date: 2.months.ago,
          amount_cents: 15000,
          description: "Old income"
        )
      end

      it 'correctly calculates net balance for cutoff' do
        GenerateMonthlyTransactionsReportJob.new.perform
        report = TransactionsReport.last

        # Simulate cutoff job
        TransactionsCutoffJob.new.perform(report.id)
        cutoff = Transaction.find_by(cutoff: true)
        expect(cutoff).to be_present
      end
    end

    context 'prevents duplicate reports' do
      before do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago,
          amount_cents: -5000
        )
      end

      it 'does not create duplicate reports for same account and cutoff_date' do
        # First run
        GenerateMonthlyTransactionsReportJob.new.perform
        first_report = TransactionsReport.last

        expect {
          GenerateMonthlyTransactionsReportJob.new.perform
        }.not_to change(TransactionsReport, :count)

        expect(TransactionsReport.last).to eq(first_report)
      end
    end

    context 'validates transactions are not deleted prematurely' do
      before do
        @old_expense = create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago,
          amount_cents: -5000,
          description: "Old transaction"
        )

        @recent_expense = create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 2.months.ago,
          amount_cents: -3000,
          description: "Recent transaction"
        )
      end
    end

    context 'with multiple money accounts' do
      let(:money_account2) { create(:money_account, account: account, user: user, name: "Bank") }

      before do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 2.months.ago,
          amount_cents: -5000,
          description: "Cash expense"
        )

        create(:expense,
          account: account,
          user: user,
          money_account: money_account2,
          transaction_date: 2.months.ago,
          amount_cents: -3000,
          description: "Bank expense"
        )
      end

      it 'creates separate cutoff transactions for each money account' do
        GenerateMonthlyTransactionsReportJob.new.perform
        report = TransactionsReport.last

        TransactionsCutoffJob.new.perform(report.id)

        cutoffs = Transaction.where(cutoff: true)
        expect(cutoffs.count).to eq(2)

        cash_cutoff = cutoffs.find_by(money_account: money_account)
        bank_cutoff = cutoffs.find_by(money_account: money_account2)

        expect(cash_cutoff.amount_cents).to eq(-5000)
        expect(bank_cutoff.amount_cents).to eq(-3000)
      end
    end
  end
end
