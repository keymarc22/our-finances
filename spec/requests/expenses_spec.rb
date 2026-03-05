require 'rails_helper'

RSpec.describe "Expenses", type: :request, sign_in: true do
  let(:account)       { @user.account }
  let(:money_account) do
    ma = create(:money_account, user: @user, account:)
    create(:incoming, money_account: ma, user: @user, account:, amount_cents: 100_000)
    ma
  end
  let(:budget)        { create(:budget, account:, user: @user) }
  let(:expense)       { create(:expense, user: @user, account:, transaction_date: Date.today, amount: -100, money_account:) }
  let(:valid_params) do
    {
      expense: {
        description: 'Test expense',
        user_id: @user.id,
        transaction_date: Date.today,
        amount: 50,
        money_account_id: money_account.id
      }
    }
  end

  describe "GET /expenses" do
    it "returns success" do
      get expenses_path
      expect(response).to have_http_status(:ok)
    end

    it "lists expenses for the current account" do
      expense
      get expenses_path
      expect(response.body).to include(expense.description)
    end

    it "supports ransack filtering" do
      expense
      get expenses_path, params: { q: { description_cont: expense.description } }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /expenses/new" do
    it "returns success" do
      get new_expense_path
      expect(response).to have_http_status(:ok)
    end

    it "sets from_dashboard flag when param is present" do
      get new_expense_path, params: { from_dashboard: 'true' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /expenses/:id/edit" do
    it "returns success" do
      get edit_expense_path(expense)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /expenses" do
    it "creates an expense with valid params" do
      expect {
        post expenses_path, params: valid_params, as: :turbo_stream
      }.to change(Expense, :count).by(1)
    end

    it "assigns the current account to the expense" do
      post expenses_path, params: valid_params, as: :turbo_stream
      expect(Expense.last.account).to eq(account)
    end

    it "stores the amount as negative" do
      post expenses_path, params: valid_params, as: :turbo_stream
      expect(Expense.last.amount_cents).to be < 0
    end

    it "does not create an expense without a money_account" do
      expect {
        post expenses_path, params: { expense: valid_params[:expense].except(:money_account_id) }, as: :turbo_stream
      }.not_to change(Expense, :count)
    end

    it "does not create an expense without a transaction_date" do
      expect {
        post expenses_path, params: { expense: valid_params[:expense].except(:transaction_date) }, as: :turbo_stream
      }.not_to change(Expense, :count)
    end

    it "creates an expense with a budget" do
      expect {
        post expenses_path, params: { expense: valid_params[:expense].merge(budget_id: budget.id) }, as: :turbo_stream
      }.to change(Expense, :count).by(1)

      expect(Expense.last.budget).to eq(budget)
    end

    it "defaults amount_currency to USD" do
      post expenses_path, params: valid_params, as: :turbo_stream
      expect(Expense.last.amount_currency).to eq('USD')
    end

    it "creates an expense with a comment" do
      post expenses_path, params: { expense: valid_params[:expense].merge(comment: 'Monthly rent') }, as: :turbo_stream
      expect(Expense.last.comment).to eq('Monthly rent')
    end

    it "does not create an expense that exceeds the money account balance" do
      expect {
        post expenses_path, params: { expense: valid_params[:expense].merge(amount: 999_999) }, as: :turbo_stream
      }.not_to change(Expense, :count)
    end

    it "creates an expense that leaves the money account at exactly zero" do
      balance_cents = money_account.balance.cents
      amount = Money.new(balance_cents).to_f

      expect {
        post expenses_path, params: { expense: valid_params[:expense].merge(amount: amount) }, as: :turbo_stream
      }.to change(Expense, :count).by(1)
    end

    context 'with currency different from account currency' do
      it "converts amount to account currency" do
        post expenses_path, params: { expense: valid_params[:expense].merge(amount: 9000, exchange_currency: 'VES', exchange_rate: 450) }, as: :turbo_stream
        expect(Expense.last.amount).to eq(Money.new(-2000, "USD"))
      end
    end
  end

  describe "GET /expenses/bulks/new" do
    it "returns success" do
      get new_bulk_expense_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /expenses/bulks" do
    let(:bulk_params) do
      {
        bulk: {
          money_account_id: money_account.id,
          user_id: @user.id,
          transaction_date: Date.today,
          exchange_currency: 'USD',
          expenses: {
            '0' => { amount: 10, description: 'Groceries', budget_id: budget.id },
            '1' => { amount: 20, description: 'Transport', budget_id: budget.id }
          }
        }
      }
    end

    it "creates multiple expenses and redirects to index" do
      expect {
        post bulk_expenses_path, params: bulk_params
      }.to change(Expense, :count).by(2)

      expect(response).to redirect_to(expenses_path)
    end

    it "assigns the current account to all expenses" do
      post bulk_expenses_path, params: bulk_params
      Expense.last(2).each do |expense|
        expect(expense.account).to eq(account)
      end
    end

    it "stores amounts as negative" do
      post bulk_expenses_path, params: bulk_params
      Expense.last(2).each do |expense|
        expect(expense.amount_cents).to be < 0
      end
    end

    it "rolls back all expenses if any fail" do
      invalid_params = bulk_params.deep_dup
      invalid_params[:bulk][:money_account_id] = nil

      expect {
        post bulk_expenses_path, params: invalid_params
      }.not_to change(Expense, :count)
    end

    it "sets flash notice on success" do
      post bulk_expenses_path, params: bulk_params
      expect(flash[:notice]).to include("2 expenses created")
    end
  end

  describe "PATCH /expenses/:id" do
    it "updates the expense amount" do
      patch expense_path(expense), params: { expense: { amount: 50 } }, as: :turbo_stream
      expect(expense.reload.amount.format).to eq('$-50.00')
    end

    it "updates the expense description" do
      patch expense_path(expense), params: { expense: { description: 'Updated description' } }, as: :turbo_stream
      expect(expense.reload.description).to eq('Updated description')
    end

    it "does not update with invalid params" do
      patch expense_path(expense), params: { expense: { money_account_id: nil } }, as: :turbo_stream
      expect(expense.reload.money_account_id).to eq(money_account.id)
    end

    it "loads dashboard data when from_dashboard is true" do
      patch expense_path(expense), params: { expense: { amount: 50, from_dashboard: 'true' } }, as: :turbo_stream
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /expenses/:id" do
    it "destroys the expense" do
      expense
      expect {
        delete expense_path(expense), as: :turbo_stream
      }.to change(Expense, :count).by(-1)
    end

    it "returns success" do
      delete expense_path(expense), as: :turbo_stream
      expect(response).to have_http_status(:ok)
    end

    it "loads dashboard data when from_dashboard is true" do
      delete expense_path(expense), params: { from_dashboard: 'true' }, as: :turbo_stream
      expect(response).to have_http_status(:ok)
    end
  end
end
