require 'rails_helper'

RSpec.describe "Budgets", type: :request, sign_in: true do
  let(:account)  { @user.account }
  let(:budget)   { create(:budget, name: "Presupuesto", amount_cents: 10000, account: account, user: @user) }

  it "GET /budgets returns success" do
    get budgets_path

    expect(response).to have_http_status(:ok)
  end

  it "POST /budgets creates a budget" do
    expect {
      post budgets_path, params: { budget: { name: "Nuevo", amount: 500, account_id: account.id, user_id: @user.id } }
    }.to change(Budget, :count).by(1)
  end

  it "PATCH /budgets/:id updates a budget" do
    expect(budget.amount.format).to eq('$100.00')

    patch budget_path(budget), params: { budget: { amount: 200 } }
    expect(budget.reload.amount.format).to eq('$200.00')
  end

  describe "monthly attribute" do
    it "PATCH /budgets/:id updates monthly to false" do
      budget.update!(monthly: true)

      patch budget_path(budget), params: { budget: { monthly: '0' } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(budget.reload.monthly).to be_falsey
    end

    it "PATCH /budgets/:id updates monthly to true" do
      budget.update!(monthly: false)

      patch budget_path(budget), params: { budget: { monthly: '1' } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(budget.reload.monthly).to be_truthy
    end
  end

  it "DELETE /budgets/:id destroys a budget" do
    delete budget_path(budget)
    expect(Budget.exists?(budget.id)).to be_falsey
  end
end
