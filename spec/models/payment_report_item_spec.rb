require 'rails_helper'

RSpec.describe PaymentReportItem, type: :model do
  let(:account) { create(:account) }
  let(:payment_report) { create(:payment_report, account: account) }

  describe "associations" do
    it "belongs to payment_report" do
      item = build(:payment_report_item, payment_report: payment_report)
      expect(item.payment_report).to eq(payment_report)
    end

    it "can optionally belong to monthly_bill" do
      bill = create(:monthly_bill, account: account)
      item = create(:payment_report_item, payment_report: payment_report, monthly_bill_id: bill.id)
      expect(item.monthly_bill).to eq(bill)
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      item = build(:payment_report_item, payment_report: payment_report)
      expect(item).to be_valid
    end

    it "is invalid without name" do
      item = build(:payment_report_item, payment_report: payment_report, name: nil)
      expect(item).not_to be_valid
    end

    it "is invalid with negative amount_cents" do
      item = build(:payment_report_item, payment_report: payment_report, amount_cents: -100)
      expect(item).not_to be_valid
    end

    it "is valid with zero amount_cents" do
      item = build(:payment_report_item, payment_report: payment_report, amount_cents: 0)
      expect(item).to be_valid
    end
  end

  describe "monetize" do
    it "stores amount as Money object" do
      item = create(:payment_report_item, payment_report: payment_report, amount_cents: 5000)
      expect(item.amount).to be_a(Money)
      expect(item.amount.cents).to eq(5000)
    end

    it "calculates amount correctly from cents" do
      item = create(:payment_report_item, payment_report: payment_report, amount_cents: 2550)
      expect(item.amount.to_f).to eq(25.5)
    end
  end

  describe "attributes" do
    it "has default values" do
      item = create(:payment_report_item, payment_report: payment_report, name: "Netflix")
      expect(item.name).to eq("Netflix")
      expect(item.amount_currency).to eq("USD")
      expect(item.save_as_monthly_bill).to be false
      expect(item.monthly_bill_id).to be nil
    end

    it "can store custom amount_currency" do
      item = create(:payment_report_item, payment_report: payment_report, amount_currency: "VES")
      expect(item.amount_currency).to eq("VES")
    end

    it "can mark as save_as_monthly_bill" do
      item = create(:payment_report_item, payment_report: payment_report, save_as_monthly_bill: true)
      expect(item.save_as_monthly_bill).to be true
    end
  end

  describe "deletion" do
    it "is destroyed when payment_report is destroyed" do
      item = create(:payment_report_item, payment_report: payment_report)
      expect { payment_report.destroy }.to change(PaymentReportItem, :count).by(-1)
    end
  end
end
