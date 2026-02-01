require 'rails_helper'

RSpec.describe TransactionsCutoffJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:money_account1) { create(:money_account, account: account, user: user, name: "Account 1") }
  let(:money_account2) { create(:money_account, account: account, user: user, name: "Account 2") }
  let(:report) { create(:transactions_report, :with_file, account: account) }

  describe '#perform' do
    context 'with positive balance transactions' do
      before do
        expense = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 5000,
          transaction_date: 7.months.ago
        )
        expense.update(transactions_report_id: report.id)
      end

      it 'creates a cutoff transaction' do
        expect {
          described_class.new.perform(report.id)
        }.to change(Transaction, :count).by(1)
      end

      it 'creates an Incoming type for positive balance' do
        described_class.new.perform(report.id)
        
        cutoff_transaction = Transaction.where(cutoff: true).last
        expect(cutoff_transaction.type).to eq("Incoming")
      end

      it 'uses absolute value for amount' do
        described_class.new.perform(report.id)
        
        cutoff_transaction = Transaction.where(cutoff: true).last
        expect(cutoff_transaction.amount_cents).to eq(5000)
      end

      it 'sets correct description' do
        described_class.new.perform(report.id)
        
        cutoff_transaction = Transaction.where(cutoff: true).last
        expect(cutoff_transaction.description).to eq("Corte de cuenta #{money_account1.name}")
      end

      it 'marks the report as completed' do
        described_class.new.perform(report.id)
        
        expect(report.reload.status).to eq('completed')
      end
    end

    context 'with negative balance transactions (expenses)' do
      before do
        # Create incoming first to have positive balance, then expense
        incoming = create(:incoming, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 10000,
          transaction_date: 8.months.ago
        )
        expense = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 15000,
          transaction_date: 7.months.ago
        )
        incoming.update(transactions_report_id: report.id)
        expense.update(transactions_report_id: report.id)
      end

      it 'creates an Expense type for negative balance' do
        described_class.new.perform(report.id)
        
        cutoff_transaction = Transaction.where(cutoff: true).last
        expect(cutoff_transaction.type).to eq("Expense")
      end

      it 'uses absolute value for negative amount' do
        described_class.new.perform(report.id)
        
        cutoff_transaction = Transaction.where(cutoff: true).last
        # Net: 10000 incoming - 15000 expense = -5000
        expect(cutoff_transaction.amount_cents).to eq(5000)
      end
    end

    context 'with zero balance' do
      before do
        incoming = create(:incoming, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 5000,
          transaction_date: 8.months.ago
        )
        expense = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 5000,
          transaction_date: 7.months.ago
        )
        incoming.update(transactions_report_id: report.id)
        expense.update(transactions_report_id: report.id)
      end

      it 'does not create a cutoff transaction for zero balance' do
        expect {
          described_class.new.perform(report.id)
        }.not_to change(Transaction.where(cutoff: true), :count)
      end

      it 'still marks the report as completed' do
        described_class.new.perform(report.id)
        
        expect(report.reload.status).to eq('completed')
      end
    end

    context 'with multiple money accounts' do
      before do
        expense1 = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 5000,
          transaction_date: 7.months.ago
        )
        expense2 = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account2,
          amount_cents: 3000,
          transaction_date: 7.months.ago
        )
        expense1.update(transactions_report_id: report.id)
        expense2.update(transactions_report_id: report.id)
      end

      it 'creates cutoff transactions for each money account' do
        expect {
          described_class.new.perform(report.id)
        }.to change(Transaction.where(cutoff: true), :count).by(2)
      end

      it 'associates cutoff transactions with correct money accounts' do
        described_class.new.perform(report.id)
        
        cutoffs = Transaction.where(cutoff: true).order(:created_at)
        money_account_ids = cutoffs.map(&:money_account_id)
        
        expect(money_account_ids).to match_array([money_account1.id, money_account2.id])
      end

      it 'calculates amounts independently for each account' do
        described_class.new.perform(report.id)
        
        cutoff1 = Transaction.where(cutoff: true, money_account: money_account1).first
        cutoff2 = Transaction.where(cutoff: true, money_account: money_account2).first
        
        expect(cutoff1.amount_cents).to eq(5000)
        expect(cutoff2.amount_cents).to eq(3000)
      end
    end

    context 'without file attached' do
      let(:report_no_file) { create(:transactions_report, account: account) }

      it 'returns early without processing' do
        expect {
          described_class.new.perform(report_no_file.id)
        }.not_to change(Transaction.where(cutoff: true), :count)
      end

      it 'does not change report status' do
        initial_status = report_no_file.status
        described_class.new.perform(report_no_file.id)
        
        expect(report_no_file.reload.status).to eq(initial_status)
      end
    end

    context 'when cutoff creation fails' do
      before do
        expense = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 5000,
          transaction_date: 7.months.ago
        )
        expense.update(transactions_report_id: report.id)
        
        # Mock save failure
        allow_any_instance_of(Transaction).to receive(:save).and_return(false)
      end

      it 'marks the report as failed' do
        described_class.new.perform(report.id)
        
        expect(report.reload.status).to eq('failed')
      end
    end

    context 'when an exception occurs' do
      before do
        expense = create(:expense, 
          account: account, 
          user: user,
          money_account: money_account1,
          amount_cents: 5000,
          transaction_date: 7.months.ago
        )
        expense.update(transactions_report_id: report.id)
        
        allow_any_instance_of(MoneyAccount).to receive(:build_transaction_cutoff)
          .and_raise(StandardError.new("Database error"))
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/TransactionsCutoffJob failed/)
        
        described_class.new.perform(report.id)
      end

      it 'marks the report as failed' do
        described_class.new.perform(report.id)
        
        expect(report.reload.status).to eq('failed')
      end
    end

    context 'with non-existent report' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.new.perform(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'job queue' do
      it 'is queued on the default queue' do
        described_class.perform_later(report.id)
        
        expect(described_class).to have_been_enqueued.on_queue("default")
      end
    end

    context 'transaction grouping edge cases' do
      before do
        # Mix of different transaction types
        3.times do |i|
          expense = create(:expense, 
            account: account, 
            user: user,
            money_account: money_account1,
            amount_cents: 1000 * (i + 1),
            transaction_date: (7 + i).months.ago
          )
          expense.update(transactions_report_id: report.id)
        end

        2.times do |i|
          incoming = create(:incoming, 
            account: account, 
            user: user,
            money_account: money_account1,
            amount_cents: 2000 * (i + 1),
            transaction_date: (8 + i).months.ago
          )
          incoming.update(transactions_report_id: report.id)
        end
      end

      it 'correctly calculates net balance across mixed transactions' do
        described_class.new.perform(report.id)
        
        cutoff = Transaction.where(cutoff: true, money_account: money_account1).first
        # Expenses: 1000 + 2000 + 3000 = 6000
        # Incomings: 2000 + 4000 = 6000
        # Net: 0, so no cutoff should be created
        expect(cutoff).to be_nil
      end
    end
  end
end
