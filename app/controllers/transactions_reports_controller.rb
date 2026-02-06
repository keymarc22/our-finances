class TransactionsReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_report, only: %i[show destroy]

  def index
    @reports = current_user.account.transactions_reports.order(created_at: :desc)
  end

  def new
    @accounts = current_user.account.money_accounts
  end

  def create
    cutoff_date = params[:cutoff_date].present? ? Date.parse(params[:cutoff_date]) : 6.months.ago.to_date
    @report = current_user.account.transactions_reports.create!(cutoff_date: cutoff_date)
    @report.reload

    redirect_to transactions_report_path(@report), notice: redirect_notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_transactions_report_path, alert: "Error al crear el reporte: #{e.record.errors.full_messages.join(', ')}"
  rescue Date::Error
    redirect_to new_transactions_report_path, alert: "Fecha de corte inválida"
  end

  def show
    @transactions_count = @report.transactions.count
    @total_amount = Money.new(@report.transactions.sum(:amount_cents))
  end

  def destroy
    transaction_count = @report.transactions.count

    
    if @report.transactions.destroy_all
      @report.destroy
      redirect_to transactions_reports_path,
                  notice: "Reporte y #{transaction_count} transacciones eliminadas exitosamente"
    else
      redirect_to transactions_report_path(@report),
                  alert: "Error al eliminar las transacciones"
    end
  end

  private

  def set_report
    @report = current_user.account.transactions_reports.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to transactions_reports_path, alert: "Reporte no encontrado"
  end

  def redirect_notice
    if @report.failed?
      return "El reporte falló: #{@report.failure_reason}"
    end

    "Reporte generado exitosamente. #{@report.transactions.count} transacciones incluidas."
  end
end
