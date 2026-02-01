class TransactionsReport < ApplicationRecord
  belongs_to :account
  has_one_attached :file

  has_many :transactions, dependent: :nullify

  after_create :generate_report!
  after_commit :notify_and_trigger_cutoff, on: :update, if: :file_attached?
  after_update :clean_transactions, if: :completed?

  validates :account_id, presence: true
  validates :cutoff_date, presence: true

  enum :status, { in_process: 0, completed: 1, failed: 2 }, default: :in_process

  def file_attached?
    file.attached?
  end

  private

  def notify_and_trigger_cutoff
    # Only run if file was just attached (check if callbacks haven't run yet)
    return if @notified

    @notified = true
    notify_account_users
    trigger_transactions_cutoff
  end

  def generate_report!
    return if file_attached?

    transactions = account.transactions.created_before(cutoff_date)
    if transactions.empty?
      Rails.logger.info "No transactions found for TransactionsReport #{id}"
      self.failed!
      return
    end

    transactions.update_all(transactions_report_id: id)
    csv_data = TransactionsReportService.new(transactions).call
    file.attach(
      io: StringIO.new(csv_data),
      filename: "transactions_report_#{id}_#{cutoff_date}.csv",
      content_type: "text/csv"
    )
    save!
  rescue => err
    failed!
    Rails.logger.error "Failed to generate TransactionsReport #{id}: #{err.message}"
    Rails.logger.error err.backtrace.join("\n")
  end

  def notify_account_users
    return unless file_attached?

    SendTransactionsReportJob.perform_later(id)
  end

  def clean_transactions
    transactions.destroy_all
  end

  def trigger_transactions_cutoff
    TransactionsCutoffJob.perform_later(id)
  end
end
