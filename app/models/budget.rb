class Budget < ApplicationRecord
  monetize :amount_cents

  enum :budget_type, %i[personal shared]

  belongs_to :account
  belongs_to :user, optional: true

  has_many :expenses, dependent: :destroy

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :user_id, presence: true, if: :personal?

  ICONS = %w[
    flame
    alarm-clock
    armchair
    award
    badge-check
    banknote
    biceps-flexed
    bookmark
    boxes
    bubbles
    cake
    car
    coffee
    concierge-bell
    cookie
    dog
    flag
    gamepad-2
    github
    hand-coins
    heart
    house
    laugh
    lock-keyhole
    medal
    music
  ].freeze

  validates :icon, presence: true, inclusion: { in: ICONS }

  def total_expenses
    @total_expenses ||= expenses.no_fixed.sum(&:amount)
  end

  def total_expenses_in_period(date_range = Date.today.beginning_of_month..Date.today.end_of_month)
    expenses.no_fixed.created_between(date_range.first, date_range.last).sum(&:amount).abs
  end

  def percentage(total = total_expenses_in_period)
    return 0 if amount.zero? || total.zero?

    (total.to_f / amount.to_f * 100).round(1)
  end
end
