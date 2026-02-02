class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :money_accounts, dependent: :destroy
  has_many :savings_plans, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :transaction_groups, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :incomings
  has_many :expenses
  has_many :outgoing_transfers
  has_many :incoming_transfers
  has_many :store_items, dependent: :destroy
  has_many :stores, dependent: :destroy
  has_many :item_prices, through: :store_items
  has_many :transactions_reports, dependent: :destroy

  def money_accounts_balance
    money_accounts.sum(&:balance)
  end
end
