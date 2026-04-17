require 'rails_helper'

RSpec.describe PayReportItemsService do
  let(:account)       { create(:account) }
  let(:user)          { create(:user, account:) }
  let(:money_account) do
    ma = create(:money_account, account:, user:)
    create(:incoming, money_account: ma, user:, account:, amount_cents: 10_000_000)
    ma
  end
  let(:report)           { create(:payment_report, account:) }
  let(:transaction_date) { Date.current }

  def build_service(selected_items:)
    described_class.new(
      account: account,
      user: user,
      report: report,
      money_account_id: money_account.id,
      selected_items: selected_items,
      transaction_date: transaction_date
    )
  end

  describe '#call' do
    context 'when no items are selected' do
      it 'returns 0 and does not create any expenses' do
        service = build_service(selected_items: [])

        expect { service.call }.not_to change(Expense, :count)
        expect(service.call).to eq(0)
      end
    end

    context 'with "bill-" items' do
      let!(:bill) { create(:monthly_bill, account:, amount_cents: 50_000) }

      it 'creates one expense per selected bill' do
        service = build_service(selected_items: ["bill-#{bill.id}"])

        expect { service.call }.to change(Expense, :count).by(1)
      end

      it 'returns the number of processed items' do
        service = build_service(selected_items: ["bill-#{bill.id}"])

        expect(service.call).to eq(1)
      end

      it 'creates the expense with the correct (negative) amount' do
        build_service(selected_items: ["bill-#{bill.id}"]).call

        expect(Expense.last.amount_cents).to eq(-50_000)
      end

      it 'uses the bill name as the expense description' do
        build_service(selected_items: ["bill-#{bill.id}"]).call

        expect(Expense.last.description).to eq(bill.name)
      end

      it 'assigns the correct money account' do
        build_service(selected_items: ["bill-#{bill.id}"]).call

        expect(Expense.last.money_account_id).to eq(money_account.id)
      end

      it 'assigns the correct transaction date' do
        build_service(selected_items: ["bill-#{bill.id}"]).call

        expect(Expense.last.transaction_date).to eq(transaction_date)
      end

      it 'creates a MonthlyBillPayment linked to the expense' do
        expect {
          build_service(selected_items: ["bill-#{bill.id}"]).call
        }.to change(MonthlyBillPayment, :count).by(1)
      end

      it 'records the correct year and month in MonthlyBillPayment' do
        build_service(selected_items: ["bill-#{bill.id}"]).call

        payment = MonthlyBillPayment.last
        expect(payment.year).to eq(transaction_date.year)
        expect(payment.month).to eq(transaction_date.month)
      end

      it 'raises an error if the bill does not belong to the account' do
        other_bill = create(:monthly_bill)
        service = build_service(selected_items: ["bill-#{other_bill.id}"])

        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with "item-" items' do
      let!(:item) { create(:payment_report_item, payment_report: report, amount_cents: 20_000) }

      it 'creates one expense per selected item' do
        service = build_service(selected_items: ["item-#{item.id}"])

        expect { service.call }.to change(Expense, :count).by(1)
      end

      it 'returns the number of processed items' do
        service = build_service(selected_items: ["item-#{item.id}"])

        expect(service.call).to eq(1)
      end

      it 'creates the expense with the correct (negative) amount' do
        build_service(selected_items: ["item-#{item.id}"]).call

        expect(Expense.last.amount_cents).to eq(-20_000)
      end

      it 'uses the item name as the expense description' do
        build_service(selected_items: ["item-#{item.id}"]).call

        expect(Expense.last.description).to eq(item.name)
      end

      it 'does not create a MonthlyBillPayment' do
        expect {
          build_service(selected_items: ["item-#{item.id}"]).call
        }.not_to change(MonthlyBillPayment, :count)
      end
    end

    context 'with a mix of bills and items' do
      let!(:bill) { create(:monthly_bill, account:) }
      let!(:item) { create(:payment_report_item, payment_report: report) }

      it 'processes all items and returns the correct total' do
        service = build_service(selected_items: ["bill-#{bill.id}", "item-#{item.id}"])

        expect(service.call).to eq(2)
      end

      it 'creates one expense per item' do
        service = build_service(selected_items: ["bill-#{bill.id}", "item-#{item.id}"])

        expect { service.call }.to change(Expense, :count).by(2)
      end
    end

    context 'when an item does not exist' do
      it 'rolls back the transaction and does not create any expenses' do
        bill = create(:monthly_bill, account:)
        service = build_service(selected_items: ["bill-#{bill.id}", "item-999999"])

        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
        expect(Expense.count).to eq(0)
      end
    end

    context 'with unknown ID formats' do
      it 'ignores them without creating expenses or raising exceptions' do
        service = build_service(selected_items: ["unknown-123", "other-456"])

        expect { service.call }.not_to change(Expense, :count)
        expect(service.call).to eq(0)
      end
    end

    context 'when transaction_date is passed as a string' do
      it 'parses the date correctly' do
        bill = create(:monthly_bill, account:)
        service = described_class.new(
          account: account,
          user: user,
          report: report,
          money_account_id: money_account.id,
          selected_items: ["bill-#{bill.id}"],
          transaction_date: "2026-04-15"
        )
        service.call

        expect(Expense.last.transaction_date).to eq(Date.new(2026, 4, 15))
      end
    end
  end
end

