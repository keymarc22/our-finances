class PaymentReportsController < ApplicationController
  def show
    @year = params[:year].present? ? params[:year].to_i : Date.current.year
    @month = params[:month].present? ? params[:month].to_i : Date.current.month
    @is_current_month = @year == Date.current.year && @month == Date.current.month

    @report = current_account.payment_reports.find_or_create_by(year: @year, month: @month) do |r|
      r.rate_a = default_exchange_rate
      r.rate_b = default_exchange_rate
    end

    @unpaid_bills = current_account.monthly_bills.active
      .order(:due_day)
      .reject(&:paid_this_month?)
    @default_rate = default_exchange_rate

    @prev_month = @month == 1 ? 12 : @month - 1
    @prev_year = @month == 1 ? @year - 1 : @year
    @next_month = @month == 12 ? 1 : @month + 1
    @next_year = @month == 12 ? @year + 1 : @year
  end

  def pay_items
    @report = find_or_create_report
    created_count = PayReportItemsService.new(
      account: current_account,
      user: current_user,
      report: @report,
      money_account_id: params[:money_account_id],
      selected_items: params[:selected_items],
      transaction_date: params[:transaction_date]
    ).call

    render json: { success: true, count: created_count }
  rescue => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  def update
    @report = find_or_create_report

    ActiveRecord::Base.transaction do
      @report.update!(
        rate_a: params.dig(:rate_a),
        rate_b: params.dig(:rate_b)
      )
      sync_items(@report, Array(params[:items]))
    end

    render json: report_json(@report)
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private


  def find_or_create_report
    rate = default_exchange_rate
    current_account.payment_reports.find_or_create_by(
      year: Date.current.year,
      month: Date.current.month
    ) do |r|
      r.rate_a = rate
      r.rate_b = rate
    end
  end

  def default_exchange_rate
    rates = ExchangeRatesService.run
    rate = rates.find { |r| r.source&.downcase&.include?("paralelo") } || rates.first
    rate&.amount&.to_f || 1.0
  end

  def sync_items(report, items_params)
    SyncPaymentReportItemsService.new(
      account: current_account,
      report: report,
      items_params: items_params
    ).call
  end

  def report_json(report)
    {
      id: report.id,
      rate_a: report.rate_a&.to_f,
      rate_b: report.rate_b&.to_f,
      items: report.payment_report_items.reload.map { |i|
        {
          id: i.id,
          name: i.name,
          amount: i.amount_cents.to_f / 100,
          currency: i.amount_currency,
          save_as_monthly_bill: i.save_as_monthly_bill,
          monthly_bill_id: i.monthly_bill_id
        }
      }
    }
  end
end
