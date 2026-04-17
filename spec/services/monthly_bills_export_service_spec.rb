require 'rails_helper'

RSpec.describe MonthlyBillsExportService do
  describe '#call' do
    let(:account) { create(:account) }
    let!(:bill1) { create(:monthly_bill, account: account, name: "Netflix", amount_cents: 1000, due_day: 5) }
    let!(:bill2) { create(:monthly_bill, account: account, name: "Spotify", amount_cents: 500, due_day: 15) }
    let(:bills) { account.monthly_bills.active.order(:due_day) }

    subject { described_class.new(bills).call }

    it 'returns a non-empty binary string' do
      result = subject
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it 'returns xlsx format' do
      result = subject
      expect(result).to start_with("PK") # ZIP file signature for xlsx
    end

    context 'with empty bills collection' do
      let(:bills) { [] }

      it 'returns a valid xlsx file' do
        result = subject
        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end
    end
  end
end
