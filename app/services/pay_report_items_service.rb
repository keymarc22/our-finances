# Service responsible for recording selected payments in a monthly payment report.
#
# For each selected item it can:
#   - Create an expense linked to a MonthlyBill and register the payment in MonthlyBillPayment.
#   - Create a manual expense from a PaymentReportItem.
#
# All expenses are created inside a database transaction, so any failure
# rolls back the entire operation.
#
# @example
#   service = PayReportItemsService.new(
#     account: current_account,
#     user: current_user,
#     report: @report,
#     money_account_id: params[:money_account_id],
#     selected_items: params[:selected_items],
#     transaction_date: params[:transaction_date]
#   )
#   created_count = service.run
class PayReportItemsService
  # @param account [Account] the authenticated user's account
  # @param user [User] the user performing the payment
  # @param report [PaymentReport] the current month's payment report
  # @param money_account_id [Integer, String] ID of the money account to debit
  # @param selected_items [Array<String>] item IDs prefixed with "bill-" or "item-"
  # @param transaction_date [Date, String] date on which the expenses are recorded
  def initialize(account:, user:, report:, money_account_id:, selected_items:, transaction_date:)
    @account = account
    @user = user
    @report = report
    @money_account = account.money_accounts.find(money_account_id)
    @selected_items = Array(selected_items)
    @transaction_date = Date.parse(transaction_date.to_s)
  end

  # Processes the selected items and creates the corresponding expenses.
  #
  # @return [Integer] number of expenses created
  # @raise [ActiveRecord::RecordInvalid] if any record fails validation
  # @raise [ActiveRecord::RecordNotFound] if a bill or item cannot be found
  def call
    created_count = 0

    ActiveRecord::Base.transaction do
      @selected_items.each do |item_id|
        if item_id.start_with?('bill-')
          bill_id = item_id.sub('bill-', '').to_i
          bill = @account.monthly_bills.find(bill_id)
          create_bill_payment(bill)
          created_count += 1
        elsif item_id.start_with?('item-')
          item_db_id = item_id.sub('item-', '').to_i
          item = PaymentReportItem.find(item_db_id)
          create_manual_payment(item)
          created_count += 1
        end
      end
    end

    created_count
  end

  private

  # Creates an expense linked to a monthly bill and records the payment in MonthlyBillPayment.
  #
  # @param bill [MonthlyBill]
  # @return [Expense]
  def create_bill_payment(bill)
    expense = @account.expenses.create!(
      amount_cents: -bill.amount_cents,
      description: bill.name,
      money_account_id: @money_account.id,
      transaction_date: @transaction_date,
      user_id: @user.id
    )

    MonthlyBillPayment.create!(
      monthly_bill_id: bill.id,
      expense_id: expense.id,
      year: @transaction_date.year,
      month: @transaction_date.month
    )
  end

  # Creates an expense from a manual report item.
  #
  # @param item [PaymentReportItem]
  # @return [Expense]
  def create_manual_payment(item)
    @account.expenses.create!(
      amount_cents: -((item.amount_cents.to_f).round),
      description: item.name,
      money_account_id: @money_account.id,
      transaction_date: @transaction_date,
      user_id: @user.id
    )
  end
end

