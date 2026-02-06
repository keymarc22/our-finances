# frozen_string_literal: true

module TransactionsReports
  class DownloadsController < ApplicationController
    before_action :authenticate_user!

    def show
      @report = current_user.account.transactions_reports.find(params[:transactions_report_id])

      unless @report.file_attached?
        redirect_to transactions_report_path(@report),
                    alert: "El archivo del reporte no está disponible"
        return
      end

      send_data @report.file.download,
                filename: @report.file.filename.to_s,
                type: @report.file.content_type,
                disposition: "attachment"
    rescue ActiveRecord::RecordNotFound
      redirect_to transactions_reports_path, alert: "Reporte no encontrado"
    end
  end
end
