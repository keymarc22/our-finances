class GenerateMonthlyTransactionsReportJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 1.hour, attempts: 3

  def perform
    retention_months = Rails.application.credentials.dig(:data_retention, :months)
    cutoff_date = retention_months.months.ago.to_date

    Account.find_each do |account|
      report = TransactionsReport.find_or_initialize_by(account:, cutoff_date:)
      next if report.persisted?

      report.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create TransactionsReport for Account #{account.id}: #{e.message}"
      next
    end
  end
end
