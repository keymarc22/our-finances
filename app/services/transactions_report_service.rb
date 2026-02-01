class TransactionsReportService
  require 'csv'
  
  HEADERS = [
    'Transaction ID',
    'Date',
    'Amount',
    'Type',
    'Registered By',
    'Account',
    'description',
    'Fixed',
    'Budget'
  ]

  def initialize(transactions)
    @transactions = transactions
  end

  def call
    CSV.generate(headers: true) do |csv|
      csv << HEADERS

      @transactions
        .includes(:user, :account, :budget)
        .in_batches(
          of: 1000,
          cursor: %i[transaction_date id],
          order: :desc
        ) do |batches|
        batches.each do |transaction|
          csv << [
            transaction.id,
            transaction.transaction_date,
            transaction.description,
            transaction.amount&.format,
            transaction.account&.name,
            transaction.budget&.name,
            transaction.type,
            transaction.user&.name,
            transaction.fixed
          ]
        end
      end
    rescue StandardError => e
      Rails.logger.error("Error generating transactions report: #{e.message}")
      raise
    end
  end
end