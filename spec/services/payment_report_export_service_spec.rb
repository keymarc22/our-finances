require 'rails_helper'

RSpec.describe PaymentReportExportService do
  describe '#call' do
    let(:account) { create(:account) }
    let!(:bill) { create(:monthly_bill, account: account, name: "Netflix", amount_cents: 1500) }
    let!(:report) do
      create(:payment_report, account: account, year: 2025, month: 4, rate_a: 50.0, rate_b: 45.0)
    end
    let!(:manual_item) do
      create(:payment_report_item, payment_report: report, name: "Extra payment", amount_cents: 2000)
    end
    let(:unpaid_bills) { [bill] }

    subject { described_class.new(report, unpaid_bills).call }

    it 'returns a non-empty binary string' do
      result = subject
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it 'returns xlsx format' do
      result = subject
      expect(result).to start_with("PK") # ZIP file signature for xlsx
    end

    context 'with empty unpaid bills and no items' do
      let(:unpaid_bills) { [] }
      let!(:empty_report) do
        create(:payment_report, account: account, year: 2025, month: 3, rate_a: 50.0, rate_b: 45.0)
      end

      it 'returns a valid xlsx file' do
        result = PaymentReportExportService.new(empty_report, []).call
        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end
    end
  end
end
