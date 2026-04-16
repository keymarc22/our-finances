require 'rails_helper'

RSpec.describe MonthlyBillPayment, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:money_account) do
    ma = create(:money_account, account: account, user: user)
    ma.incomings.create!(amount_cents: 1_000_000, description: "Ingreso", user: user, transaction_date: Date.today)
    ma
  end
  let(:bill) { create(:monthly_bill, account: account) }

  def build_payment(overrides = {})
    expense = create(:expense, account: account, user: user, money_account: money_account,
                     transaction_date: Date.today)
    build(:monthly_bill_payment, monthly_bill: bill, expense: expense, **overrides)
  end

  def create_payment(overrides = {})
    expense = create(:expense, account: account, user: user, money_account: money_account,
                     transaction_date: Date.today)
    create(:monthly_bill_payment, monthly_bill: bill, expense: expense, **overrides)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build_payment).to be_valid
    end

    it "is invalid without year" do
      expect(build_payment(year: nil)).not_to be_valid
    end

    it "is invalid without month" do
      expect(build_payment(month: nil)).not_to be_valid
    end

    it "is invalid with month 0" do
      expect(build_payment(month: 0)).not_to be_valid
    end

    it "is invalid with month 13" do
      expect(build_payment(month: 13)).not_to be_valid
    end

    it "is invalid when the same bill is paid twice in the same month" do
      create_payment(year: 2026, month: 4)
      duplicate = build_payment(year: 2026, month: 4)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:monthly_bill_id]).to be_present
    end

    it "is valid for the same bill in a different month" do
      create_payment(year: 2026, month: 3)
      expect(build_payment(year: 2026, month: 4)).to be_valid
    end
  end
end
