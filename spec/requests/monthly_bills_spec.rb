require 'rails_helper'

RSpec.describe "MonthlyBills", type: :request, sign_in: true do
  let(:account) { @user.account }
  let(:bill) { create(:monthly_bill, account: account) }

  describe "GET /monthly_bills" do
    it "returns success" do
      get monthly_bills_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /monthly_bills/new" do
    it "returns success" do
      get new_monthly_bill_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /monthly_bills" do
    let(:valid_params) { { monthly_bill: { name: "Internet", amount: 50 } } }

    it "creates a monthly bill" do
      expect {
        post monthly_bills_path, params: valid_params, as: :turbo_stream
      }.to change(MonthlyBill, :count).by(1)
    end

    it "does not create a bill with invalid params" do
      expect {
        post monthly_bills_path, params: { monthly_bill: { name: "" } }, as: :turbo_stream
      }.not_to change(MonthlyBill, :count)
    end
  end

  describe "GET /monthly_bills/:id/edit" do
    it "returns success" do
      get edit_monthly_bill_path(bill)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /monthly_bills/:id" do
    it "updates the bill" do
      patch monthly_bill_path(bill), params: { monthly_bill: { name: "Updated Name" } }, as: :turbo_stream
      expect(bill.reload.name).to eq("Updated Name")
    end

    it "does not update with invalid params" do
      original_name = bill.name
      patch monthly_bill_path(bill), params: { monthly_bill: { name: "" } }, as: :turbo_stream
      expect(bill.reload.name).to eq(original_name)
    end
  end

  describe "DELETE /monthly_bills/:id" do
    it "marks the bill as inactive" do
      delete monthly_bill_path(bill), as: :turbo_stream
      expect(bill.reload.active).to be false
    end

    it "does not hard-delete the record" do
      delete monthly_bill_path(bill), as: :turbo_stream
      expect(MonthlyBill.exists?(bill.id)).to be true
    end
  end
end
