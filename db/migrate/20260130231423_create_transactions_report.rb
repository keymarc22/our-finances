class CreateTransactionsReport < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions_reports do |t|
      t.references :account, null: false, foreign_key: true
      t.date :cutoff_date, null: false
      t.boolean :email_sent, default: false, null: false
      t.integer :status, default: 0, null: false
      t.text :transaction_ids
      t.datetime :email_sent_at

      t.timestamps
    end

    add_column :transactions, :cutoff, :boolean, default: false, null: false
    add_index :transactions_reports, %i[account_id cutoff_date], unique: true
  end
end
