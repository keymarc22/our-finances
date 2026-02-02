class AddTransactionsReportIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :transactions_report, foreign_key: true, index: true
  end
end
