class TransactionsReport < ApplicationRecord
  belongs_to :account
  has_one_attached :file
  
  has_many :transactions, dependent: :nullify
  
  after_create :generate_report!
  after_update :notify_account_users, if: :file_attached_changed?
  after_update :trigger_transactions_cutoff, if: :file_attached_changed?
  after_update :clean_transactions, if: :completed!
  
  validates :account_id, presence: true
  validates :cutoff_date, presence: true

  enum status: %i[in_process completed failed]
  
  def file_attached?
    file.attached?
  end
  
  private

  def generate_report!
    return if file_attached?

    transactions = account.transactions.created_before(cutoff_date)
    if transactions.empty?
      Rails.logger.info "No transactions found for TransactionsReport #{id}"
      self.failed!
      return
    end
    
    transactions.update_all(transactions_report_id: id)
    file.attach TransactionsReportService(id, transactions).call
  rescue => err
    failed!
    Rails.logger.error "Failed to generate TransactionsReport #{id}: #{err.message}"
  end
  
  def notify_account_users
    return unless file_attached?

    SendTransactionReportJob.perform_later(id)
  end
  
  def clean_transactions
    transactions.destroy_all
  end
  
  def trigger_transactions_cutoff
    TransactionsCutoffJob.perform_later(id)
  end
end
