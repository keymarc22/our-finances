class PaymentReportItem < ApplicationRecord
  belongs_to :payment_report
  belongs_to :monthly_bill, optional: true

  monetize :amount_cents

  validates :name, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
end
