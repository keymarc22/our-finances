require 'rails_helper'

RSpec.describe Dashboard, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:money_account) do
    ma = create(:money_account, account: account, user: user)
    ma.incomings.create!(amount_cents: 10_000_000, description: "Ingreso", user: user, transaction_date: Date.today)
    ma
  end
  let(:dashboard) { Dashboard.new(account) }

  def create_expense(date:, amount_cents:)
    create(:expense, account: account, user: user, money_account: money_account,
           transaction_date: date, amount_cents: amount_cents)
  end

  def create_bill(overrides = {})
    create(:monthly_bill, account: account, **overrides)
  end

  describe "#monthly_bills" do
    it "returns active bills for the account ordered by due_day" do
      bill_15 = create_bill(due_day: 15)
      bill_5  = create_bill(due_day: 5)
      _inactive = create(:monthly_bill, :inactive, account: account, due_day: 1)

      result = dashboard.monthly_bills
      expect(result).to eq([ bill_5, bill_15 ])
    end

    it "preloads current month payment into each bill" do
      bill = create_bill
      expense = create_expense(date: Date.today, amount_cents: -10_000)
      payment = bill.monthly_bill_payments.create!(expense: expense, year: Date.today.year, month: Date.today.month)

      result = dashboard.monthly_bills
      loaded_bill = result.find { |b| b.id == bill.id }
      expect(loaded_bill.payment_for_current_month).to eq(payment)
    end

    it "returns empty array when account has no active bills" do
      create(:monthly_bill, :inactive, account: account)
      expect(dashboard.monthly_bills).to be_empty
    end
  end

  describe "#pending_monthly_bills" do
    it "returns bills not paid this month" do
      unpaid = create_bill
      paid_bill = create_bill
      expense = create_expense(date: Date.today, amount_cents: -10_000)
      paid_bill.monthly_bill_payments.create!(expense: expense, year: Date.today.year, month: Date.today.month)

      expect(dashboard.pending_monthly_bills).to include(unpaid)
      expect(dashboard.pending_monthly_bills).not_to include(paid_bill)
    end

    it "returns empty array when all bills are paid" do
      bill = create_bill
      expense = create_expense(date: Date.today, amount_cents: -10_000)
      bill.monthly_bill_payments.create!(expense: expense, year: Date.today.year, month: Date.today.month)

      expect(dashboard.pending_monthly_bills).to be_empty
    end
  end

  describe "#total_monthly_obligations" do
    it "sums the amounts of all active bills" do
      create_bill(amount_cents: 100_000)
      create_bill(amount_cents: 50_000)

      expect(dashboard.total_monthly_obligations).to eq(Money.new(150_000))
    end

    it "returns zero when there are no active bills" do
      expect(dashboard.total_monthly_obligations).to eq(Money.new(0))
    end
  end

  describe "#daily_expenses_this_month" do
    it "returns one entry per day from day 1 to today" do
      travel_to Date.new(2026, 4, 10) do
        result = Dashboard.new(account).daily_expenses_this_month
        expect(result.length).to eq(10)
        expect(result.first[:day]).to eq(1)
        expect(result.last[:day]).to eq(10)
      end
    end

    it "sums expense amounts per day" do
      travel_to Date.new(2026, 4, 5) do
        create_expense(date: Date.new(2026, 4, 3), amount_cents: -20_000)
        create_expense(date: Date.new(2026, 4, 3), amount_cents: -30_000)
        create_expense(date: Date.new(2026, 4, 5), amount_cents: -10_000)

        result = Dashboard.new(account).daily_expenses_this_month

        day_3 = result.find { |d| d[:day] == 3 }
        day_5 = result.find { |d| d[:day] == 5 }
        day_1 = result.find { |d| d[:day] == 1 }

        expect(day_3[:amount]).to eq(500.0)
        expect(day_5[:amount]).to eq(100.0)
        expect(day_1[:amount]).to eq(0)
      end
    end

    it "returns zero for days with no expenses" do
      travel_to Date.new(2026, 4, 3) do
        result = Dashboard.new(account).daily_expenses_this_month
        expect(result.all? { |d| d[:amount] == 0 }).to be true
      end
    end
  end
end
