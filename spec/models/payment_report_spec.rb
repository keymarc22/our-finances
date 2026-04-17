require 'rails_helper'

RSpec.describe PaymentReport, type: :model do
  let(:account) { create(:account) }

  describe "associations" do
    it "belongs to account" do
      report = build(:payment_report, account: account)
      expect(report.account).to eq(account)
    end

    it "has many payment_report_items" do
      report = create(:payment_report, account: account)
      item = create(:payment_report_item, payment_report: report)
      expect(report.payment_report_items).to include(item)
    end

    it "destroys items when report is destroyed" do
      report = create(:payment_report, account: account)
      create(:payment_report_item, payment_report: report)
      expect { report.destroy }.to change(PaymentReportItem, :count).by(-1)
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      report = build(:payment_report, account: account)
      expect(report).to be_valid
    end

    it "is invalid without year" do
      report = build(:payment_report, account: account, year: nil)
      expect(report).not_to be_valid
    end

    it "is invalid without month" do
      report = build(:payment_report, account: account, month: nil)
      expect(report).not_to be_valid
    end

    it "is valid with rate_a and rate_b > 0" do
      report = build(:payment_report, account: account, rate_a: 50.0, rate_b: 45.0)
      expect(report).to be_valid
    end

    it "is invalid with rate_a <= 0" do
      report = build(:payment_report, account: account, rate_a: 0)
      expect(report).not_to be_valid
    end

    it "is invalid with rate_b <= 0" do
      report = build(:payment_report, account: account, rate_b: -5.0)
      expect(report).not_to be_valid
    end

    it "is valid with nil rates" do
      report = build(:payment_report, account: account, rate_a: nil, rate_b: nil)
      expect(report).to be_valid
    end
  end

  describe "uniqueness" do
    it "has unique index at database level on account_id, year, month" do
      create(:payment_report, account: account, year: 2026, month: 4, rate_a: 50.0, rate_b: 45.0)
      duplicate = build(:payment_report, account: account, year: 2026, month: 4)
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows different months" do
      create(:payment_report, account: account, year: 2026, month: 4)
      report = create(:payment_report, account: account, year: 2026, month: 5)
      expect(report).to be_persisted
    end

    it "allows different accounts" do
      create(:payment_report, account: account, year: 2026, month: 4)
      other_account = create(:account)
      report = create(:payment_report, account: other_account, year: 2026, month: 4)
      expect(report).to be_persisted
    end
  end

  describe "creation" do
    it "creates a valid report with defaults" do
      report = create(:payment_report, account: account)
      expect(report).to be_persisted
      expect(report.rate_a).to eq(55.5)
      expect(report.rate_b).to eq(45.0)
    end
  end
end
