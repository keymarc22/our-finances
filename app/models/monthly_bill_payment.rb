class MonthlyBillPayment < ApplicationRecord
  belongs_to :monthly_bill
  belongs_to :expense, class_name: "Expense", foreign_key: :expense_id

  validates :year, :month, presence: true
  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :monthly_bill_id, uniqueness: { scope: [ :year, :month ], message: "already paid for this month" }

  after_destroy :destroy_linked_expense

  private

  def destroy_linked_expense
    expense&.destroy
  end
end
