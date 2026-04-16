class MonthlyBill < ApplicationRecord
  belongs_to :account
  belongs_to :money_account, optional: true
  belongs_to :budget, optional: true
  has_many :monthly_bill_payments, dependent: :destroy

  monetize :amount_cents

  validates :name, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :due_day, numericality: { in: 1..31, only_integer: true }, allow_nil: true

  scope :active, -> { where(active: true) }

  def paid_this_month?
    @current_payment_loaded ? @current_payment.present? : monthly_bill_payments.exists?(year: Date.today.year, month: Date.today.month)
  end

  def payment_for_current_month
    if @current_payment_loaded
      @current_payment
    else
      monthly_bill_payments.find_by(year: Date.today.year, month: Date.today.month)
    end
  end

  def overdue?
    return false if due_day.nil? || paid_this_month?

    Date.today.day > due_day
  end

  def preload_current_payment(payment)
    @current_payment = payment
    @current_payment_loaded = true
  end
end
