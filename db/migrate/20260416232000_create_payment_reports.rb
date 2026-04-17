class CreatePaymentReports < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_reports do |t|
      t.bigint :account_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :rate_a, precision: 10, scale: 4
      t.decimal :rate_b, precision: 10, scale: 4
      t.timestamps

      t.index [:account_id, :year, :month], unique: true, name: "idx_payment_reports_unique"
    end

    create_table :payment_report_items do |t|
      t.bigint :payment_report_id, null: false
      t.bigint :monthly_bill_id
      t.string :name, null: false
      t.integer :amount_cents, default: 0, null: false
      t.string :amount_currency, default: "USD", null: false
      t.boolean :save_as_monthly_bill, default: false, null: false
      t.timestamps

      t.index :payment_report_id, name: "index_payment_report_items_on_report_id"
    end

    add_foreign_key :payment_reports, :accounts
    add_foreign_key :payment_report_items, :payment_reports
    add_foreign_key :payment_report_items, :monthly_bills, column: :monthly_bill_id
  end
end
