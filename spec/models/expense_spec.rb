require 'rails_helper'

RSpec.describe Expense, type: :model do
  let(:account) { create(:account, name: "Cuenta test") }
  let(:user) { create(:user, email: "test@example.com", account: account) }
  let(:money_account) { create(:money_account, name: "Efectivo", account: account, user: user) }
  let(:budget) { create(:budget, name: "Presupuesto", amount: 1000, account: account, user: user) }

  it "is valid with valid attributes" do
    expense = Expense.new(
      user: user,
      money_account: money_account,
      transaction_date: Date.today,
      amount_cents: -1000,
      budget: budget,
      account: account
    )
    expect(expense).to be_valid
  end

  it "is invalid without user_id if no budget_id" do
    expense = Expense.new(
      money_account: money_account,
      transaction_date: Date.today,
      amount_cents: -1000,
      account: account
    )
    expect(expense).not_to be_valid
    expect(expense.errors[:user_id]).to be_present
  end

  it "calculates total_splits_percentage" do
    expense = Expense.create!(
      description: "Grocery",
      user: user,
      money_account: money_account,
      transaction_date: Date.today,
      amount_cents: -1000,
      account: account
    )
    expense.expense_splits.create!(user: user, percentage: 100)
    expect(expense.total_splits_percentage).to eq(100)
  end

  it "validates splits sum to 100 percent for shared" do
    expense = Expense.new(
      user: user,
      money_account: money_account,
      transaction_date: Date.today,
      amount_cents: -1000,
      transaction_type: :shared,
      account: account
    )
    expense.expense_splits.build(user: user, percentage: 50)
    expense.valid?
    expect(expense.errors[:percentage]).to include("Los porcentajes deben sumar exactamente 100%")
  end
end
