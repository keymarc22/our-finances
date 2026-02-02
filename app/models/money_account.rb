class MoneyAccount < ApplicationRecord
  belongs_to :account
  belongs_to :user

  has_many :transactions # every type of transaction
  has_many :incomings
  has_many :expenses
  has_many :outgoing_transfers
  has_many :incoming_transfers

  validates :name, presence: true
  accepts_nested_attributes_for :incomings, allow_destroy: true

  def balance
    Money.new transactions.sum(:amount_cents)
  end

  def incomings_total
    Money.new transactions.where(type: %w[Incoming IncomingTransfer]).sum(:amount_cents)
  end

  def outgoings_total
    Money.new transactions.where(type: %w[Expense OutgoingTransfer]).sum(:amount_cents)
  end

  def build_transaction_cutoff(amount_cents)
    type = amount_cents.positive? ? "Incoming" : "Expense"

    account.transactions.build(
      money_account: self,
      amount_cents: amount_cents,
      transaction_date: Date.today,
      description: "Corte de cuenta #{name}",
      type:,
      cutoff: true,
      transaction_type: "cutoff"
    )
  end
end
