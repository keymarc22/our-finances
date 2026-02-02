require 'rails_helper'

RSpec.describe "Expenses", type: :request, sign_in: true do
  let(:account)       { @user.account }
  let(:expense)       { create(:expense, user: @user, account:, transaction_date: Date.today, amount: -100) }
  let(:money_account) { create(:money_account, user: @user, account:) }

  it "GET /expenses/new returns success" do
    get new_expense_path
    expect(response).to have_http_status(:ok)
  end

  it "POST /expenses creates an expense" do
    expect {
      post expenses_path, params: {
        expense: {
          description: 'new expense',
          user_id: @user.id,
          account_id: account.id,
          transaction_date: Date.today,
          amount: 500,
          money_account_id: money_account.id
        }
      }
    }.to change(Expense, :count).by(1)
  end

  it "PATCH /expenses/:id updates an expense" do
    patch expense_path(expense), params: { expense: { amount: 200 } }
    expect(expense.reload.amount.format).to eq('$-200.00')
  end

  it "DELETE /expenses/:id destroys an expense" do
    delete expense_path(expense)
    expect(Expense.count).to eq 0
  end
end
