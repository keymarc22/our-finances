require 'rails_helper'

RSpec.describe Budget, type: :model do
  let(:account) { create(:account, name: "Cuenta test") }
  let(:user) { create(:user, email: "test@example.com", account: account) }
  let(:money_account) { create(:money_account, account: account, user: user) }

  it "is valid with valid attributes" do
    budget = Budget.new(name: "Presupuesto", amount: 1000, account: account, user: user)
    expect(budget).to be_valid
  end

  it "is invalid without name" do
    budget = Budget.new(amount: 1000, account: account, user: user)
    expect(budget).not_to be_valid
    expect(budget.errors[:name]).to be_present
  end

  it "is invalid without amount" do
    budget = Budget.new(name: "Presupuesto", account: account, user: user)
    expect(budget).not_to be_valid
    expect(budget.errors[:amount]).to be_present
  end

  it "calculates percentage" do
    budget = Budget.create!(name: "Presupuesto", amount: 1000, account: account, user: user)
    budget.expenses.create!(amount_cents: 500, description: 'Grocery', user: user, money_account: money_account, transaction_date: Date.today, account: account)
    expect(budget.percentage).to eq(0.5)
  end
end
