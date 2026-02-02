class TransactionsReportMailer < ApplicationMailer
  def notify_account_users(report_id)
    @report = TransactionsReport.find(report_id)
    @account = @report.account
    @users = @account.users
    @date = @report.cutoff_date

    attachments[@report.file.filename.to_s] = @report.file.download if @report.file.attached?
    mail(
      to: @users.pluck(:email).join(","),
      subject: "Your Transactions Summary for #{@date.strftime('%B %Y')}"
    )
  end
end
