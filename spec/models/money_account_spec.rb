require 'rails_helper'

RSpec.describe MoneyAccount, type: :model do
  let(:account) { create(:account, name: "Cuenta test") }
  let(:user) { create(:user, email: "test@example.com", password: "123456", password_confirmation: "123456", account: account) }

  it "is valid with valid attributes" do
    money_account = MoneyAccount.new(name: "Efectivo", account: account, user: user)
    expect(money_account).to be_valid
  end

  it "is invalid without name" do
    money_account = MoneyAccount.new(account: account, user: user)
    expect(money_account).not_to be_valid
    expect(money_account.errors[:name]).to be_present
  end

  it "calculates balance" do
    money_account = MoneyAccount.create!(name: "Efectivo", account: account, user: user)
    money_account.incomings.create!(amount_cents: 1000, description: 'test', user: user, transaction_date: Date.today)
    money_account.expenses.create!(amount_cents: -500, description: 'test', user: user, transaction_date: Date.today, account: account)
    expect(money_account.balance).to eq(Money.new(500, "USD"))
  end
end
