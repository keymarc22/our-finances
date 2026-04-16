class CreateMonthlyBillPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_bill_payments do |t|
      t.references :monthly_bill, null: false, foreign_key: true
      t.bigint :expense_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.datetime :paid_at, null: false, default: -> { "NOW()" }

      t.timestamps
    end

    add_index :monthly_bill_payments, [ :monthly_bill_id, :year, :month ],
              unique: true, name: "idx_bill_payments_unique"
    add_index :monthly_bill_payments, [ :year, :month ]
    add_index :monthly_bill_payments, :expense_id
    add_foreign_key :monthly_bill_payments, :transactions, column: :expense_id
  end
end
