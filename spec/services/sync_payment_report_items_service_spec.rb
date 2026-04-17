require 'rails_helper'

RSpec.describe SyncPaymentReportItemsService do
  let(:account) { create(:account) }
  let(:report)  { create(:payment_report, account:) }

  def build_service(items_params)
    described_class.new(account:, report:, items_params:)
  end

  describe '#call' do
    context 'when items_params is empty' do
      it 'destroys all existing items' do
        create_list(:payment_report_item, 2, payment_report: report)

        expect { build_service([]).call }.to change(PaymentReportItem, :count).by(-2)
      end

      it 'does not raise' do
        expect { build_service([]).call }.not_to raise_error
      end
    end

    context 'when creating new items (no id in params)' do
      let(:items_params) do
        [{ name: "Netflix", amount: 15.99, currency: "USD", save_as_monthly_bill: false }]
      end

      it 'creates one item per entry' do
        expect { build_service(items_params).call }.to change(PaymentReportItem, :count).by(1)
      end

      it 'stores the correct name' do
        build_service(items_params).call
        expect(PaymentReportItem.last.name).to eq("Netflix")
      end

      it 'converts the amount to cents correctly' do
        build_service(items_params).call
        expect(PaymentReportItem.last.amount_cents).to eq(1599)
      end

      it 'stores the currency' do
        build_service(items_params).call
        expect(PaymentReportItem.last.amount_currency).to eq("USD")
      end

      it 'defaults currency to USD when not provided' do
        build_service([{ name: "Misc", amount: 5.0, save_as_monthly_bill: false }]).call
        expect(PaymentReportItem.last.amount_currency).to eq("USD")
      end
    end

    context 'when updating an existing item' do
      let!(:item) { create(:payment_report_item, payment_report: report, name: "Old name", amount_cents: 5_000) }

      let(:items_params) do
        [{ id: item.id, name: "New name", amount: 99.0, currency: "USD", save_as_monthly_bill: false }]
      end

      it 'does not create a new item' do
        expect { build_service(items_params).call }.not_to change(PaymentReportItem, :count)
      end

      it 'updates the name' do
        build_service(items_params).call
        expect(item.reload.name).to eq("New name")
      end

      it 'updates the amount_cents' do
        build_service(items_params).call
        expect(item.reload.amount_cents).to eq(9900)
      end
    end

    context 'when an item is absent from incoming params' do
      let!(:kept_item)    { create(:payment_report_item, payment_report: report) }
      let!(:removed_item) { create(:payment_report_item, payment_report: report) }

      it 'destroys items whose IDs are not included' do
        params = [{ id: kept_item.id, name: kept_item.name, amount: kept_item.amount_cents / 100.0,
                    currency: kept_item.amount_currency, save_as_monthly_bill: false }]

        expect { build_service(params).call }.to change(PaymentReportItem, :count).by(-1)
        expect(PaymentReportItem.exists?(removed_item.id)).to be(false)
      end
    end

    context 'when save_as_monthly_bill is true and no monthly_bill_id exists' do
      let(:items_params) do
        [{ name: "Gym", amount: 30.0, currency: "USD", save_as_monthly_bill: true }]
      end

      it 'creates a MonthlyBill' do
        expect { build_service(items_params).call }.to change(MonthlyBill, :count).by(1)
      end

      it 'links the created bill to the item via monthly_bill_id' do
        build_service(items_params).call
        item = PaymentReportItem.last
        expect(item.monthly_bill_id).to eq(MonthlyBill.last.id)
      end

      it 'sets the bill name and amount from the item' do
        build_service(items_params).call
        bill = MonthlyBill.last
        expect(bill.name).to eq("Gym")
        expect(bill.amount_cents).to eq(3000)
      end
    end

    context 'when save_as_monthly_bill is true but monthly_bill_id is already set' do
      let!(:existing_bill) { create(:monthly_bill, account:) }
      let!(:item) do
        create(:payment_report_item, payment_report: report,
               save_as_monthly_bill: true, monthly_bill_id: existing_bill.id)
      end

      it 'does not create a new MonthlyBill' do
        params = [{ id: item.id, name: item.name, amount: item.amount_cents / 100.0,
                    currency: item.amount_currency, save_as_monthly_bill: true }]

        expect { build_service(params).call }.not_to change(MonthlyBill, :count)
      end
    end

    context 'when save_as_monthly_bill is false' do
      let(:items_params) do
        [{ name: "Spotify", amount: 10.0, currency: "USD", save_as_monthly_bill: false }]
      end

      it 'does not create a MonthlyBill' do
        expect { build_service(items_params).call }.not_to change(MonthlyBill, :count)
      end
    end

    context 'when save_as_monthly_bill is passed as the string "true"' do
      let(:items_params) do
        [{ name: "Internet", amount: 25.0, currency: "USD", save_as_monthly_bill: "true" }]
      end

      it 'treats it as truthy and creates a MonthlyBill' do
        expect { build_service(items_params).call }.to change(MonthlyBill, :count).by(1)
      end
    end

    context 'with multiple items mixed (create and update)' do
      let!(:existing_item) { create(:payment_report_item, payment_report: report) }

      let(:items_params) do
        [
          { id: existing_item.id, name: "Updated", amount: 5.0, currency: "USD", save_as_monthly_bill: false },
          { name: "New item", amount: 12.0, currency: "EUR", save_as_monthly_bill: false }
        ]
      end

      it 'updates existing and creates new items' do
        expect { build_service(items_params).call }.to change(PaymentReportItem, :count).by(1)
        expect(existing_item.reload.name).to eq("Updated")
      end
    end
  end
end

