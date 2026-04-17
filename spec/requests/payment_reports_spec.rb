require 'rails_helper'

RSpec.describe "PaymentReports", type: :request, sign_in: true do
  let(:account) { @user.account }
  let!(:bill1) { create(:monthly_bill, account: account, name: "Netflix", amount_cents: 1000) }
  let!(:bill2) { create(:monthly_bill, account: account, name: "Spotify", amount_cents: 500) }

  describe "GET /payment_report" do
    context "when no report exists for current month" do
      it "returns success" do
        get payment_report_path
        expect(response).to have_http_status(:ok)
      end

      it "creates a payment report for current month" do
        expect {
          get payment_report_path
        }.to change(PaymentReport, :count).by(1)
      end

      it "sets default rates from ExchangeRatesService" do
        allow_any_instance_of(PaymentReportsController)
          .to receive(:default_exchange_rate).and_return(50.0)

        get payment_report_path
        report = account.payment_reports.find_by(year: Date.current.year, month: Date.current.month)

        expect(report.rate_a).to eq(50.0)
        expect(report.rate_b).to eq(50.0)
      end

      it "displays unpaid monthly bills" do
        get payment_report_path
        expect(response.body).to include(bill1.name)
        expect(response.body).to include(bill2.name)
      end
    end

    context "when report exists for current month" do
      let!(:report) do
        create(:payment_report, account: account, year: Date.current.year,
               month: Date.current.month, rate_a: 55.5, rate_b: 45.0)
      end

      it "loads the existing report" do
        expect {
          get payment_report_path
        }.not_to change(PaymentReport, :count)
      end

      it "uses existing rates" do
        get payment_report_path
        expect(response.body).to include("55.5")
        expect(response.body).to include("45")
      end
    end
  end

  describe "PATCH /payment_report" do
    let!(:report) do
      create(:payment_report, account: account, year: Date.current.year,
             month: Date.current.month, rate_a: 50.0, rate_b: 45.0)
    end

    context "with valid parameters" do
      let(:params) do
        {
          rate_a: 55.0,
          rate_b: 48.0,
          items: [
            {
              id: nil,
              name: "Manual payment",
              amount: 100.0,
              currency: "USD",
              save_as_monthly_bill: false
            }
          ]
        }
      end

      it "updates the rates" do
        patch payment_report_path, params: params, as: :json
        report.reload
        expect(report.rate_a).to eq(55.0)
        expect(report.rate_b).to eq(48.0)
      end

      it "creates new manual items" do
        expect {
          patch payment_report_path, params: params, as: :json
        }.to change(PaymentReportItem, :count).by(1)
      end

      it "returns updated report JSON" do
        patch payment_report_path, params: params, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["rate_a"]).to eq(55.0)
        expect(json["rate_b"]).to eq(48.0)
        expect(json["items"]).to be_an(Array)
      end
    end

    context "with manual item to be saved as monthly bill" do
      let(:params) do
        {
          rate_a: 50.0,
          rate_b: 45.0,
          items: [
            {
              id: nil,
              name: "New recurring bill",
              amount: 75.0,
              currency: "USD",
              save_as_monthly_bill: true
            }
          ]
        }
      end

      it "creates a MonthlyBill" do
        expect {
          patch payment_report_path, params: params, as: :json
        }.to change(MonthlyBill, :count).by(1)
      end

      it "sets monthly_bill_id on the payment_report_item" do
        patch payment_report_path, params: params, as: :json
        item = PaymentReportItem.last
        expect(item.monthly_bill_id).to be_present
      end

      it "creates the bill with correct attributes" do
        patch payment_report_path, params: params, as: :json
        bill = MonthlyBill.last
        expect(bill.name).to eq("New recurring bill")
        expect(bill.amount_cents).to eq(7500)
      end
    end

    context "with item update" do
      let!(:item) { create(:payment_report_item, payment_report: report, name: "Old name") }

      let(:params) do
        {
          rate_a: 50.0,
          rate_b: 45.0,
          items: [
            {
              id: item.id,
              name: "Updated name",
              amount: 50.0,
              currency: "USD",
              save_as_monthly_bill: false
            }
          ]
        }
      end

      it "updates existing items" do
        patch payment_report_path, params: params, as: :json
        item.reload
        expect(item.name).to eq("Updated name")
      end

      it "does not create new items" do
        expect {
          patch payment_report_path, params: params, as: :json
        }.not_to change(PaymentReportItem, :count)
      end
    end

    context "with item removal" do
      let!(:item1) { create(:payment_report_item, payment_report: report, name: "Keep") }
      let!(:item2) { create(:payment_report_item, payment_report: report, name: "Delete") }

      let(:params) do
        {
          rate_a: 50.0,
          rate_b: 45.0,
          items: [
            {
              id: item1.id,
              name: "Keep",
              amount: 100.0,
              currency: "USD",
              save_as_monthly_bill: false
            }
          ]
        }
      end

      it "removes items not in the payload" do
        expect {
          patch payment_report_path, params: params, as: :json
        }.to change(PaymentReportItem, :count).by(-1)
        expect(PaymentReportItem.exists?(item2.id)).to be false
      end

      it "keeps items in the payload" do
        patch payment_report_path, params: params, as: :json
        expect(PaymentReportItem.exists?(item1.id)).to be true
      end
    end

    context "without changing save_as_monthly_bill on second save" do
      let!(:item) do
        patch payment_report_path, params: {
          rate_a: 50.0,
          rate_b: 45.0,
          items: [
            { id: nil, name: "Test", amount: 10.0, currency: "USD", save_as_monthly_bill: true }
          ]
        }, as: :json
        PaymentReportItem.last
      end

      it "does not create duplicate MonthlyBill" do
        second_bill_id = item.monthly_bill_id

        patch payment_report_path, params: {
          rate_a: 50.0,
          rate_b: 45.0,
          items: [
            { id: item.id, name: "Test", amount: 10.0, currency: "USD", save_as_monthly_bill: true }
          ]
        }, as: :json

        item.reload
        expect(item.monthly_bill_id).to eq(second_bill_id)
        expect(MonthlyBill.where(id: second_bill_id).count).to eq(1)
      end
    end

    context "with invalid rates" do
      let(:params) do
        {
          rate_a: 0,
          rate_b: -5,
          items: []
        }
      end

      it "returns validation errors" do
        patch payment_report_path, params: params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /payment_report/pay_items" do
    it "requires a money_account_id" do
      post pay_items_payment_report_path, params: { selected_items: [], transaction_date: Date.current.to_s }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns a JSON response" do
      report = create(:payment_report, account: account, year: Date.current.year, month: Date.current.month)
      money_account = create(:money_account, account: account, user: @user)

      post pay_items_payment_report_path, params: {
        selected_items: [],
        money_account_id: money_account.id,
        transaction_date: Date.current.to_s
      }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("count")
      expect(json["count"]).to eq(0)
    end
  end

  describe "GET /payment_report/export" do
    let!(:report) do
      create(:payment_report, account: account, year: Date.current.year, month: Date.current.month, rate_a: 50.0, rate_b: 45.0)
    end

    it "returns success" do
      get export_payment_report_path(year: report.year, month: report.month, format: :xlsx)
      expect(response).to have_http_status(:ok)
    end

    it "returns xlsx content type" do
      get export_payment_report_path(year: report.year, month: report.month, format: :xlsx)
      expect(response.content_type).to include("spreadsheetml")
    end

    it "sets attachment disposition" do
      get export_payment_report_path(year: report.year, month: report.month, format: :xlsx)
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "includes filename in response" do
      get export_payment_report_path(year: report.year, month: report.month, format: :xlsx)
      expect(response.headers["Content-Disposition"]).to include("payment_report")
    end

    it "redirects when report does not exist" do
      get export_payment_report_path(year: 2020, month: 1, format: :xlsx)
      expect(response).to redirect_to(payment_report_path(year: 2020, month: 1))
    end
  end
end
