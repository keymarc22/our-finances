require 'axlsx'

class MonthlyBillsExportService
  def initialize(monthly_bills)
    @monthly_bills = monthly_bills
  end

  def call
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "Monthly Bills") do |ws|
        ws.add_row ["Name", "Amount", "Due Day", "Budget", "Account"]

        @monthly_bills.each do |bill|
          ws.add_row [
            bill.name,
            bill.amount.to_f,
            bill.due_day,
            bill.budget&.name,
            bill.money_account&.name
          ]
        end
      end
    end.to_stream.read
  end
end
