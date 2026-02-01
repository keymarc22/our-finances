require 'rails_helper'

RSpec.describe TransactionsReportService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:money_account) { create(:money_account, account: account, user: user) }
  let(:budget) { create(:budget, account: account, user: user) }
  
  describe '#call' do
    context 'with valid transactions' do
      let!(:expense1) do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          budget: budget,
          transaction_date: 7.months.ago,
          amount_cents: 5000,
          description: 'Grocery shopping',
          fixed: false
        )
      end

      let!(:expense2) do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 8.months.ago,
          amount_cents: 10000,
          description: 'Restaurant',
          fixed: true
        )
      end

      let(:transactions) { account.transactions.where(id: [expense1.id, expense2.id]) }
      let(:service) { described_class.new(transactions) }

      it 'generates a CSV with correct headers' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv.headers).to eq(TransactionsReportService::HEADERS)
      end

      it 'includes all transactions in the CSV' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv.length).to eq(2)
      end

      it 'includes correct transaction data' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        first_row = csv[0]
        expect(first_row['Transaction ID']).to eq(expense2.id.to_s)
        expect(first_row['Date']).to eq(expense2.transaction_date.to_s)
        expect(first_row['Description']).to eq('Restaurant')
      end

      it 'formats amount correctly' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        row = csv.find { |r| r['Transaction ID'] == expense1.id.to_s }
        expect(row['Amount']).to match(/50/)
      end

      it 'includes user information' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv[0]['Registered By']).to eq(user.name)
      end

      it 'includes account information' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv[0]['Account']).to eq(account.name)
      end

      it 'includes budget information when present' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        row = csv.find { |r| r['Transaction ID'] == expense1.id.to_s }
        expect(row['Budget']).to eq(budget.name)
      end

      it 'includes fixed flag' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        row = csv.find { |r| r['Transaction ID'] == expense2.id.to_s }
        expect(row['Fixed']).to eq('true')
      end

      it 'includes transaction type' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv[0]['Type']).to eq('Expense')
      end
    end

    context 'with empty transactions' do
      let(:transactions) { Transaction.none }
      let(:service) { described_class.new(transactions) }

      it 'generates CSV with only headers' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv.headers).to eq(TransactionsReportService::HEADERS)
        expect(csv.length).to eq(0)
      end
    end

    context 'with large number of transactions' do
      before do
        # Create 2500 transactions to test batch processing (over 2 batches of 1000)
        2500.times do |i|
          create(:expense,
            account: account,
            user: user,
            money_account: money_account,
            transaction_date: (7 + i).days.ago,
            amount_cents: 1000 + i
          )
        end
      end

      let(:transactions) { account.transactions }
      let(:service) { described_class.new(transactions) }

      it 'processes all transactions in batches' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv.length).to eq(2500)
      end

      it 'maintains order (most recent first)' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        # Should be ordered by transaction_date DESC
        first_date = Date.parse(csv[0]['Date'])
        last_date = Date.parse(csv[-1]['Date'])
        
        expect(first_date).to be >= last_date
      end
    end

    context 'with transactions missing associations' do
      let!(:transaction_without_budget) do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          budget: nil,
          transaction_date: 7.months.ago
        )
      end

      let(:transactions) { account.transactions.where(id: transaction_without_budget.id) }
      let(:service) { described_class.new(transactions) }

      it 'handles missing budget gracefully' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv[0]['Budget']).to be_nil.or eq('')
      end
    end

    context 'error handling' do
      let(:transactions) { account.transactions }
      let(:service) { described_class.new(transactions) }

      before do
        create(:expense, account: account, user: user, money_account: money_account)
        allow(transactions).to receive(:in_batches).and_raise(StandardError.new("Database error"))
      end

      it 'logs error and re-raises' do
        expect(Rails.logger).to receive(:error).with(/Error generating transactions report/)
        
        expect { service.call }.to raise_error(StandardError, "Database error")
      end
    end

    context 'with different transaction types' do
      let!(:expense) do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago,
          description: 'Expense transaction'
        )
      end

      let!(:incoming) do
        create(:incoming,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago,
          description: 'Income transaction'
        )
      end

      let(:transactions) { account.transactions.where(id: [expense.id, incoming.id]) }
      let(:service) { described_class.new(transactions) }

      it 'includes different transaction types' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        types = csv.map { |row| row['Type'] }.uniq
        expect(types).to include('Expense', 'Incoming')
      end
    end

    context 'CSV format validation' do
      let!(:expense) do
        create(:expense,
          account: account,
          user: user,
          money_account: money_account,
          transaction_date: 7.months.ago,
          description: 'Test with, comma'
        )
      end

      let(:transactions) { account.transactions.where(id: expense.id) }
      let(:service) { described_class.new(transactions) }

      it 'properly escapes special characters in CSV' do
        csv_content = service.call
        
        # Ensure valid CSV parsing
        expect { CSV.parse(csv_content, headers: true) }.not_to raise_error
      end

      it 'maintains data integrity with special characters' do
        csv_content = service.call
        csv = CSV.parse(csv_content, headers: true)
        
        expect(csv[0]['Description']).to eq('Test with, comma')
      end
    end
  end
end
