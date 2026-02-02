class TransactionsCutoffJob < ApplicationJob
  queue_as :default

  def perform(report_id)
    report = TransactionsReport.find(report_id)
    return unless report.file_attached?

    transactions = report.transactions
    raise "No transactions found for report #{report_id}" if transactions.empty?

    success = transactions.group_by(&:money_account).all? do |money_account, group|
      process_money_account_cutoff(money_account, group)
    end

    success ? report.completed! : report.failed!("One or more cutoff transactions failed to process")
  rescue => e
    Rails.logger.error "TransactionsCutoffJob failed for report #{report_id}: #{e.message}"
    report&.failed!(e.message)
  end

  private

  def process_money_account_cutoff(money_account, transactions)
    amount_cents = transactions.sum(&:amount_cents)
    return true if amount_cents.zero?

    transaction = money_account.build_transaction_cutoff(amount_cents)
    transaction.save!
  rescue => err
    Rails.logger.error "Failed to create cutoff transaction for MoneyAccount #{money_account.id}: #{err.message}"
    false
  end
end
