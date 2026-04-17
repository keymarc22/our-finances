class PaymentReport < ApplicationRecord
  belongs_to :account
  has_many :payment_report_items, dependent: :destroy

  validates :year, :month, presence: true
  validates :rate_a, :rate_b, numericality: { greater_than: 0 }, allow_nil: true
end
