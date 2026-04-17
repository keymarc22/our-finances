require 'caxlsx'

class PaymentReportExportService
  def initialize(report, unpaid_bills)
    @report = report
    @unpaid_bills = unpaid_bills
  end

  def call
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "Payment Report") do |ws|
        month_name = Date::MONTHNAMES[@report.month]
        ws.add_row ["#{month_name} #{@report.year} - Payment Report"]
        ws.add_row []

        ws.add_row ["Rate BCV (USD → Bs)", @report.rate_a]
        ws.add_row ["Exchange Rate (Bs → USD)", @report.rate_b]
        ws.add_row []

        ws.add_row [
          "Description",
          "Type",
          "Amount (USD)",
          "Bs (Rate BCV)",
          "To Change (USD)"
        ]

        # Monthly bills
        @unpaid_bills.each do |bill|
          amount_usd = bill.amount.to_f
          amount_bs = amount_usd * (@report.rate_a || 1)
          amount_usd_change = amount_bs / (@report.rate_b || 1)

          ws.add_row [
            bill.name,
            "Monthly Bill",
            amount_usd,
            amount_bs,
            amount_usd_change
          ]
        end

        # Manual items
        @report.payment_report_items.each do |item|
          amount_usd = item.amount.to_f
          amount_bs = amount_usd * (@report.rate_a || 1)
          amount_usd_change = amount_bs / (@report.rate_b || 1)

          ws.add_row [
            item.name,
            "Manual",
            amount_usd,
            amount_bs,
            amount_usd_change
          ]
        end
      end
    end.to_stream.read
  end
end
