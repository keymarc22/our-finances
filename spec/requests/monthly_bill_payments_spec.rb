require 'rails_helper'

RSpec.describe "MonthlyBillPayments", type: :request, sign_in: true do
  let(:account) { @user.account }
  let(:money_account) do
    ma = create(:money_account, account: account, user: @user)
    ma.incomings.create!(amount_cents: 10_000_000, description: "Ingreso", user: @user, transaction_date: Date.today)
    ma
  end
  let(:bill) { create(:monthly_bill, account: account) }

  describe "GET /monthly_bills/:monthly_bill_id/monthly_bill_payments/new" do
    it "returns success" do
      get new_monthly_bill_monthly_bill_payment_path(bill)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /monthly_bills/:monthly_bill_id/monthly_bill_payments" do
    let(:valid_params) do
      {
        expense: {
          amount: "50",
          money_account_id: money_account.id,
          transaction_date: Date.today.to_s
        }
      }
    end

    it "creates a payment and an associated expense" do
      expect {
        post monthly_bill_monthly_bill_payments_path(bill), params: valid_params, as: :turbo_stream
      }.to change(MonthlyBillPayment, :count).by(1)
        .and change(Expense, :count).by(1)
    end

    it "marks the bill as paid this month after creation" do
      post monthly_bill_monthly_bill_payments_path(bill), params: valid_params, as: :turbo_stream
      expect(bill.reload.paid_this_month?).to be true
    end

    it "does not create a duplicate payment for the same month" do
      post monthly_bill_monthly_bill_payments_path(bill), params: valid_params, as: :turbo_stream

      expect {
        post monthly_bill_monthly_bill_payments_path(bill), params: valid_params, as: :turbo_stream
      }.not_to change(MonthlyBillPayment, :count)
    end
  end

  describe "DELETE /monthly_bills/:monthly_bill_id/monthly_bill_payments/:id" do
    let!(:payment) do
      expense = create(:expense, account: account, user: @user, money_account: money_account,
                       transaction_date: Date.today)
      create(:monthly_bill_payment, monthly_bill: bill, expense: expense,
             year: Date.today.year, month: Date.today.month)
    end

    it "destroys the payment" do
      expect {
        delete monthly_bill_monthly_bill_payment_path(bill, payment), as: :turbo_stream
      }.to change(MonthlyBillPayment, :count).by(-1)
    end
  end
end
