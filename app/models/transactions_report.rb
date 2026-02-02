class TransactionsReport < ApplicationRecord
  belongs_to :account
  has_one_attached :file

  has_many :transactions, dependent: :nullify

  after_create :generate_report!
  # after_update :clean_transactions, if: :completed?
  after_commit :notify_account_users, if: -> { @file_attached_just_now }
  after_commit :trigger_transactions_cutoff, if: -> { @file_attached_just_now }

  validates :account_id, presence: true
  validates :cutoff_date, presence: true

  enum :status, { in_process: 0, completed: 1, failed: 2 }, default: :in_process

  def file_attached?
    file.attached?
  end

  def failed!(err)
    update(status: :failed, failure_reason: err.to_s)
  end

  private

  def generate_report!
    return if file_attached?

    transactions = account.transactions.created_between(cutoff_date, created_at)
    if transactions.empty?
      Rails.logger.info "No transactions found for TransactionsReport #{id}"
      self.failed!("No transactions found for the specified cutoff date")
      return
    end

    transactions.update_all(transactions_report_id: id)
    csv_data = TransactionsReportService.new(transactions).call
    # Mark that the file is being attached in this instance so the after_commit
    # callback can detect it's the attachment event and run notification + cutoff.
    @file_attached_just_now = true
    file.attach(
      io: StringIO.new(csv_data),
      filename: "transactions_report_#{id}_#{cutoff_date}.csv",
      content_type: "text/csv"
    )
  rescue => err
    failed!(err.message)
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
