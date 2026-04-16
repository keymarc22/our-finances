class Expense < Transaction
  attr_accessor :converted
  
  enum :transaction_type, { personal: 0, shared: 1, cutoff: 2 }

  enum :frequency, {
    once: 0,
    weekly: 1,
    monthly: 2,
    bimonthly: 3,
    thrimonthly: 4,
    annually: 5
  }, default: :monthly

  belongs_to :user, optional: true
  belongs_to :money_account
  belongs_to :budget, optional: true
  belongs_to :transaction_group, optional: true

  has_many :expense_splits, foreign_key: :expense_id, dependent: :destroy
  has_many :expense_participants, through: :expense_splits, source: :user

  before_validation :convert_currency
  before_validation :set_default_exchange_rate

  validates :amount_cents, presence: true, numericality: { less_than: 0 }
  validates :money_account_id, :transaction_date, presence: true, unless: :budget_id
  validates :user_id, presence: true, unless: -> { cutoff? || budget_id.present? }
  validate :exchange_data
  validate :check_balance, if: :amount_cents_changed?

  scope :fixed, -> { where(fixed: true) }

  def expense?
    true
  end

  def total_splits_percentage
    expense_splits.sum(&:percentage)
  end

  def amount_for_user(user)
    split = expense_splits.find_by(user: user)
    return 0 unless split
    (amount * split.percentage / 100.0).round(2)
  end

  def split_details
    expense_splits.includes(:user).map do |split|
      {
        user: split.user,
        percentage: split.percentage,
        amount: (amount * split.percentage / 100.0).round(2)
      }
    end
  end

  def amount_formatted
    amount.format
  end

  def parent
    money_account || budget || user || transaction_group
  end

  def amount=(value)
    return super(value) if value.nil?

    if value.respond_to?(:abs)
      super(-value.abs)
    else
      str = value.to_s
      str = "-#{str}" unless str.start_with?("-")
      super(str)
    end
  end
  
  def by_exchange?
    exchange_currency.present? && exchange_rate.present? && exchange_currency != amount_currency
  end

  private

  def set_default_exchange_rate
    self.exchange_rate = 1.0 if exchange_rate.blank?
  end

  def set_account_id
    self.account_id = parent.account_id
  end
  
  def check_balance
    unless money_account && money_account.balance_for(amount)
      errors.add(:base, "Insufficient funds in the money account.")
      throw(:abort)
    end
  end
  
  def exchange_data
    return if exchange_currency == amount_currency || converted? || exchange_currency == amount_currency
    
    errors.add(:base, "Both expense currency and exchange rate must be provided for currency conversion.")
    throw(:abort)
  end
  
  def converted?
    converted
  end

  def convert_currency
    return if converted?
    return if exchange_currency.blank? || exchange_rate.blank?
    return if exchange_currency == amount_currency

    converted = (amount_cents.abs / exchange_rate.to_f).round
    self.amount_cents = -converted
    self.converted = true
  end
end
