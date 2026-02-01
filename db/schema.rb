# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_30_231423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "budgets", force: :cascade do |t|
    t.string "name", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "budget_type", default: 0, null: false
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.string "color", default: "#000000", null: false
    t.string "icon", default: "flame", null: false
    t.index ["account_id"], name: "index_budgets_on_account_id"
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "expense_splits", force: :cascade do |t|
    t.integer "expense_id", null: false
    t.integer "user_id", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.integer "percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_expense_splits_on_expense_id"
    t.index ["user_id"], name: "index_expense_splits_on_user_id"
  end

  create_table "item_prices", force: :cascade do |t|
    t.bigint "store_item_id", null: false
    t.bigint "store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.index ["store_id", "store_item_id"], name: "index_item_prices_on_store_and_item", unique: true
    t.index ["store_id"], name: "index_item_prices_on_store_id"
    t.index ["store_item_id"], name: "index_item_prices_on_store_item_id"
  end

  create_table "money_accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_money_accounts_on_account_id"
    t.index ["user_id"], name: "index_money_accounts_on_user_id"
  end

  create_table "savings_plans", force: :cascade do |t|
    t.string "name", null: false
    t.integer "target_amount_cents", default: 0, null: false
    t.string "target_amount_currency", default: "USD", null: false
    t.integer "money_account_id", null: false
    t.date "deadline", null: false
    t.integer "status", default: 0, null: false
    t.integer "plan_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_savings_plans_on_account_id"
    t.index ["money_account_id"], name: "index_savings_plans_on_money_account_id"
  end

  create_table "store_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "package", null: false
    t.string "barcode"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "barcode"], name: "index_store_items_on_account_id_and_barcode", unique: true, where: "((barcode IS NOT NULL) AND ((barcode)::text <> ''::text))"
    t.index ["account_id", "name"], name: "index_store_items_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_store_items_on_account_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_stores_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_stores_on_account_id"
  end

  create_table "transaction_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.integer "expenses_count", default: 0, null: false
    t.index ["account_id"], name: "index_transaction_groups_on_account_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "description", null: false
    t.integer "transaction_type", default: 0, null: false
    t.boolean "fixed", default: false, null: false
    t.date "transaction_date"
    t.integer "money_account_id"
    t.integer "user_id"
    t.string "type", default: "Expense", null: false
    t.integer "savings_plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.text "comment"
    t.integer "frequency", default: 1, null: false
    t.integer "interval", default: 1, null: false
    t.bigint "account_id", null: false
    t.bigint "budget_id"
    t.bigint "transaction_group_id"
    t.bigint "transferer_money_account_id"
    t.boolean "cutoff", default: false, null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["budget_id"], name: "index_transactions_on_budget_id"
    t.index ["money_account_id"], name: "index_transactions_on_money_account_id"
    t.index ["savings_plan_id"], name: "index_transactions_on_savings_plan_id"
    t.index ["transaction_date", "id"], name: "index_transactions_on_transaction_date_and_id", order: :desc
    t.index ["transaction_group_id"], name: "index_transactions_on_transaction_group_id"
    t.index ["transferer_money_account_id"], name: "index_transactions_on_transferer_money_account_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "transactions_reports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.date "cutoff_date", null: false
    t.boolean "email_sent", default: false, null: false
    t.integer "status", default: 0, null: false
    t.text "transaction_ids"
    t.datetime "email_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "cutoff_date"], name: "index_transactions_reports_on_account_id_and_cutoff_date", unique: true
    t.index ["account_id"], name: "index_transactions_reports_on_account_id"
  end

  create_table "user_savings_plans", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "savings_plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["savings_plan_id"], name: "index_user_savings_plans_on_savings_plan_id"
    t.index ["user_id"], name: "index_user_savings_plans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id", "email"], name: "index_users_on_account_id_and_email", unique: true
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "budgets", "accounts"
  add_foreign_key "budgets", "users"
  add_foreign_key "expense_splits", "transactions", column: "expense_id"
  add_foreign_key "expense_splits", "users"
  add_foreign_key "item_prices", "store_items"
  add_foreign_key "item_prices", "stores"
  add_foreign_key "money_accounts", "accounts"
  add_foreign_key "money_accounts", "users"
  add_foreign_key "savings_plans", "accounts"
  add_foreign_key "savings_plans", "money_accounts"
  add_foreign_key "transaction_groups", "accounts"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "budgets"
  add_foreign_key "transactions", "money_accounts"
  add_foreign_key "transactions", "money_accounts", column: "transferer_money_account_id"
  add_foreign_key "transactions", "users"
  add_foreign_key "transactions_reports", "accounts"
  add_foreign_key "user_savings_plans", "users"
  add_foreign_key "users", "accounts"
end
