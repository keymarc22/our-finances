class Expense < Transaction
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

  accepts_nested_attributes_for :expense_splits, allow_destroy: true, reject_if: :all_blank

  validates :amount_cents, presence: true, numericality: { less_than: 0 }
  validates :money_account_id, :transaction_date, presence: true, unless: :budget_id
  validates :user_id, presence: true, unless: -> { cutoff? || budget_id.present? }
  validate :splits_sum_to_100_percent, if: :shared?

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

  private

  def splits_sum_to_100_percent
    return unless shared? && expense_splits.present?

    unless total_splits_percentage == 100
      errors.add(:percentage, "Los porcentajes deben sumar exactamente 100%")
    end
  end

  def set_account_id
    self.account_id = parent.account_id
  end
end
