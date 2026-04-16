class CreateMonthlyBills < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_bills do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :amount_cents, null: false, default: 0
      t.string :amount_currency, null: false, default: "USD"
      t.integer :due_day
      t.references :money_account, null: true, foreign_key: true
      t.references :budget, null: true, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :monthly_bills, [ :account_id, :active ]
  end
end
