class AddExpenseRateToTransaction < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :exchange_rate, :decimal, precision: 10, scale: 2, default: 1.0, null: false
    add_column :transactions, :exchange_currency, :string, default: "USD", null: false
  end
end
