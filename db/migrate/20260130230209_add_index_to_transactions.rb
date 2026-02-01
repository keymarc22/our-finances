class AddIndexToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_index :transactions, %i[transaction_date id], order: { transaction_date: :desc, id: :desc }
  end
end
