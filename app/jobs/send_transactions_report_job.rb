class SendTransactionsReportJob < ApplicationJob
  queue_as :mailers

  after_perform do |job|
    transaction_report_id = job.arguments.first
    TransactionsReport.find(transaction_report_id).update(email_sent: true, email_sent_at: Time.current)
  end

  def perform(transaction_report_id)
    TransactionsReportMailer.notify_account_users(transaction_report_id).deliver_now
  end
end
