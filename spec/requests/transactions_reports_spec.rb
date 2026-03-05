require 'rails_helper'

RSpec.describe "TransactionsReports", type: :request, sign_in: true do
  let(:user)          { @user }
  let(:account)       { user.account }
  let(:money_account) { create(:money_account, :with_incoming, account:, user:, name: "Efectivo") }
  let(:budget)        { create(:budget, account:, user:) }

  before do
    money_account.incomings.last.update!(amount: 100_000)
  end

  # Creates a report with file attached but without running generate_report! callback
  # so we can control exactly which transactions belong to the report.
  def create_report_with_file
    TransactionsReport.skip_callback(:create, :after, :generate_report!)
    report = TransactionsReport.create!(account:, cutoff_date: 8.months.ago.to_date, status: :completed)
    report.file.attach(
      io: StringIO.new("test,data\n1,2"),
      filename: "report.csv",
      content_type: "text/csv"
    )
    TransactionsReport.set_callback(:create, :after, :generate_report!)
    report
  end

  describe "DELETE /transactions_reports/:id" do
    context "when destroying a report with expenses" do
      let!(:report) { create_report_with_file }
      let!(:expenses) do
        3.times.map do |i|
          create(:expense, account:, user:, money_account:, budget:,
            transactions_report: report,
            transaction_date: 7.months.ago,
            amount_cents: -(1000 * (i + 1)),
            description: "Expense #{i + 1}"
          )
        end
      end

      it "creates a cutoff transaction that preserves the balance" do
        original_balance = money_account.balance
        total_expenses = expenses.sum(&:amount_cents) # -6000

        expect {
          delete transactions_report_path(report)
        }.to change { Transaction.where(cutoff: true).count }.by(1)

        cutoff = Transaction.find_by(cutoff: true, money_account:)
        expect(cutoff).to be_present
        expect(cutoff.amount_cents).to eq(total_expenses)
        expect(cutoff.description).to eq("Corte de cuenta Efectivo")
        expect(cutoff.type).to eq("Expense")

        # Balance should remain the same after cutoff replaces original transactions
        expect(money_account.reload.balance).to eq(original_balance)
      end

      it "destroys the report and its transactions" do
        expect {
          delete transactions_report_path(report)
        }.to change(TransactionsReport, :count).by(-1)
          .and change { Transaction.where(cutoff: false).where(transactions_report: report).count }.to(0)
      end

      it "redirects with success notice" do
        delete transactions_report_path(report)
        expect(response).to redirect_to(transactions_reports_path)
        follow_redirect!
        expect(response.body).to include("transacciones eliminadas exitosamente")
      end
    end

    context "when destroying a report with mixed transactions (expenses and incomings)" do
      let!(:report) { create_report_with_file }
      let!(:expense) do
        create(:expense, account:, user:, money_account:, budget:,
          transactions_report: report,
          transaction_date: 7.months.ago,
          amount_cents: -5000
        )
      end
      let!(:incoming) do
        create(:incoming, account:, user:, money_account:,
          transactions_report: report,
          transaction_date: 7.months.ago,
          amount_cents: 8000
        )
      end

      it "creates a cutoff with the net positive amount as Incoming" do
        original_balance = money_account.balance
        net_amount = expense.amount_cents + incoming.amount_cents # 3000

        expect {
          delete transactions_report_path(report)
        }.to change { Transaction.where(cutoff: true).count }.by(1)

        cutoff = Transaction.find_by(cutoff: true, money_account:)
        expect(cutoff.amount_cents).to eq(net_amount)
        expect(cutoff.type).to eq("Incoming")
        expect(money_account.reload.balance).to eq(original_balance)
      end
    end

    context "when destroying a report with multiple money accounts" do
      let(:money_account2) { create(:money_account, :with_incoming, account:, user:, name: "Banco") }
      let!(:report) { create_report_with_file }

      let!(:expense_cash) do
        create(:expense, account:, user:, money_account:, budget:,
          transactions_report: report,
          transaction_date: 7.months.ago,
          amount_cents: -3000
        )
      end

      let!(:expense_bank) do
        money_account2.incomings.last.update!(amount: 100_000)
        create(:expense, account:, user:, money_account: money_account2, budget:,
          transactions_report: report,
          transaction_date: 7.months.ago,
          amount_cents: -7000
        )
      end

      it "creates separate cutoff transactions for each money account" do
        cash_balance = money_account.balance
        bank_balance = money_account2.balance

        expect {
          delete transactions_report_path(report)
        }.to change { Transaction.where(cutoff: true).count }.by(2)

        cash_cutoff = Transaction.find_by(cutoff: true, money_account:)
        bank_cutoff = Transaction.find_by(cutoff: true, money_account: money_account2)

        expect(cash_cutoff.amount_cents).to eq(-3000)
        expect(bank_cutoff.amount_cents).to eq(-7000)

        expect(money_account.reload.balance).to eq(cash_balance)
        expect(money_account2.reload.balance).to eq(bank_balance)
      end
    end
  end
end
