class TransactionsCutoffJob < ApplicationJob
  queue_as :default

  def perform(report_id)
    report = TransactionsReport.find(report_id)
    return unless report.file_attached?

    success = report.transactions.group_by(&:money_account).all? do |money_account, group|
      process_money_account_cutoff(money_account, group)
    end

    success ? report.completed! : report.failed!
  rescue => e
    Rails.logger.error "TransactionsCutoffJob failed for report #{report_id}: #{e.message}"
    report.failed!
  end
  
  private
  
  def process_money_account_cutoff(money_account, transactions)
    amount_cents = transactions.sum(&:amount_cents)
    return true if amount_cents.zero?
  
    transaction = money_account.build_transaction_cutoff(amount_cents)
    transaction.save
  end
end
