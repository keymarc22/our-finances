require 'rails_helper'

RSpec.describe MonthlyBill, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:money_account) do
    ma = create(:money_account, account: account, user: user)
    ma.incomings.create!(amount_cents: 1_000_000, description: "Ingreso", user: user, transaction_date: Date.today)
    ma
  end
  let(:bill) { create(:monthly_bill, account: account) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:monthly_bill, account: account)).to be_valid
    end

    it "is invalid without name" do
      expect(build(:monthly_bill, account: account, name: nil)).not_to be_valid
    end

    it "is invalid with amount zero" do
      expect(build(:monthly_bill, account: account, amount_cents: 0)).not_to be_valid
    end

    it "is invalid with negative amount" do
      expect(build(:monthly_bill, account: account, amount_cents: -100)).not_to be_valid
    end

    it "is invalid with due_day out of range" do
      expect(build(:monthly_bill, account: account, due_day: 32)).not_to be_valid
    end

    it "is valid with due_day nil" do
      expect(build(:monthly_bill, account: account, due_day: nil)).to be_valid
    end

    it "is valid with due_day in 1..31" do
      expect(build(:monthly_bill, account: account, due_day: 1)).to be_valid
      expect(build(:monthly_bill, account: account, due_day: 31)).to be_valid
    end
  end

  describe "scopes" do
    it ".active returns only active bills" do
      active = create(:monthly_bill, account: account, active: true)
      inactive = create(:monthly_bill, :inactive, account: account)

      expect(MonthlyBill.active).to include(active)
      expect(MonthlyBill.active).not_to include(inactive)
    end
  end

  describe "#paid_this_month?" do
    it "returns false when there is no payment for the current month" do
      expect(bill.paid_this_month?).to be false
    end

    it "returns true when a payment exists for the current month" do
      expense = create(:expense, account: account, user: user, money_account: money_account,
                       transaction_date: Date.today)
      bill.monthly_bill_payments.create!(expense: expense, year: Date.today.year, month: Date.today.month)

      expect(bill.paid_this_month?).to be true
    end
  end

  describe "#payment_for_current_month" do
    it "returns nil when no payment exists" do
      expect(bill.payment_for_current_month).to be_nil
    end

    it "returns the payment for the current month" do
      expense = create(:expense, account: account, user: user, money_account: money_account,
                       transaction_date: Date.today)
      payment = bill.monthly_bill_payments.create!(expense: expense, year: Date.today.year, month: Date.today.month)

      expect(bill.payment_for_current_month).to eq(payment)
    end
  end

  describe "#overdue?" do
    it "returns false when due_day is nil" do
      bill.due_day = nil
      expect(bill.overdue?).to be false
    end

    it "returns false when already paid this month" do
      expense = create(:expense, account: account, user: user, money_account: money_account,
                       transaction_date: Date.today)
      bill.update!(due_day: 1)
      bill.monthly_bill_payments.create!(expense: expense, year: Date.today.year, month: Date.today.month)

      expect(bill.overdue?).to be false
    end

    it "returns true when today is past due_day and not paid" do
      travel_to Date.new(2026, 4, 20) do
        bill.due_day = 10
        expect(bill.overdue?).to be true
      end
    end

    it "returns false when today is before or on due_day and not paid" do
      travel_to Date.new(2026, 4, 5) do
        bill.due_day = 10
        expect(bill.overdue?).to be false
      end
    end
  end

  describe "#preload_current_payment" do
    it "caches the payment and uses it in paid_this_month?" do
      fake_payment = double("MonthlyBillPayment")
      bill.preload_current_payment(fake_payment)
      expect(bill.paid_this_month?).to be true
    end

    it "caches nil and returns false from paid_this_month?" do
      bill.preload_current_payment(nil)
      expect(bill.paid_this_month?).to be false
    end

    it "caches the payment and returns it from payment_for_current_month" do
      fake_payment = double("MonthlyBillPayment")
      bill.preload_current_payment(fake_payment)
      expect(bill.payment_for_current_month).to eq(fake_payment)
    end
  end
end
