class AddMonthlyFlagToBudget < ActiveRecord::Migration[8.0]
  def change
    add_column :budgets, :monthly, :boolean, default: true
  end
end
