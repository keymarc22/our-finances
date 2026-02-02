class Transaction < ApplicationRecord
  monetize :amount_cents

  enum :interval, {
    weekly: 1,
    monthly: 2,
    yearly: 3
  }

  belongs_to :account
  belongs_to :transactions_report, optional: true
  belongs_to :budget, optional: true
  belongs_to :user, optional: true
  belongs_to :money_account

  scope :created_between, ->(start_date, end_date) {
    where(transaction_date: start_date..end_date)
  }

  scope :created_before, ->(date) {
    where("transaction_date < ?", date.to_date.beginning_of_day)
  }

  validates :frequency, :interval, presence: true
  before_validation :set_account_id, unless: -> { account_id.present? }

  scope :no_fixed, -> { where(fixed: false) }

  def expense?
    false
  end

  def incoming?
    false
  end

  def transfer?
    false
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[account_id amount_cents amount_currency budget_id comment created_at description fixed frequency id id_value interval money_account_id savings_plan_id transaction_date transaction_group_id transaction_type type updated_at user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account budget expense_participants expense_splits money_account transaction_group user]
  end

  private

  def set_account_id
    raise "redifined method called"
  end
end
