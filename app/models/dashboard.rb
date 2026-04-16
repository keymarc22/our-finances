require_relative "../queries/total_incomes"
require_relative "../queries/account_expenses"

class Dashboard
  def initialize(account)
    @account = account
  end

  def current_balance
    @account_balance ||= MoneyAccountsBalance.new(@account).balance
  end

  def previous_balance
    @prev_account_balance ||= @account.transactions.where("transaction_date < ?", beginning_of_month).sum(&:amount)
  end

  def balances_higher_than_previous_period?
    account_balance > prev_account_balance
  end

  def budgets
    @budgets ||= @account
      .budgets
      .monthly
      .includes(:user)
  end

  def current_budget
    @current_budget ||= budgets.sum(&:amount)
  end

  def recent_expenses
    @expenses ||= Queries::AccountExpenses
      .new(@account, start_date: Date.today.beginning_of_week, end_date: Date.today.end_of_week)
      .call
      .order(transaction_date: :desc, created_at: :desc)
      .limit(15)
  end

  def total_expenses_this_month
    @total_expenses ||= Queries::AccountExpenses
      .new(@account, start_date: beginning_of_month, end_date: end_of_month)
      .call
      .sum(&:amount)
      .abs
  end

  def budget_percentage
    return 0 if current_budget.zero?

    ((total_expenses_this_month.to_f / current_budget.to_f) * 100).round(2)
  end

  def total_incomes_this_month
    @total_incomes ||= Queries::TotalIncomes
      .new(@account, start_date: beginning_of_month, end_date: end_of_month)
      .call
  end

  def saving_amount_this_month
    (total_incomes_this_month.to_f - total_expenses_this_month.to_f)
  end

  def saving_rate_percentage
    total = total_incomes_this_month.to_f
    return 0.0 if total.zero?

    ((saving_amount_this_month.to_f / total) * 100).round(2)
  end

  def monthly_bills
    @monthly_bills ||= begin
      bills = @account.monthly_bills.active.order(:due_day).to_a
      payments = MonthlyBillPayment
        .where(monthly_bill_id: bills.map(&:id), year: Date.today.year, month: Date.today.month)
        .index_by(&:monthly_bill_id)
      bills.each { |b| b.preload_current_payment(payments[b.id]) }
    end
  end

  def pending_monthly_bills
    @pending_monthly_bills ||= monthly_bills.reject(&:paid_this_month?)
  end

  def total_monthly_obligations
    @total_monthly_obligations ||= monthly_bills.sum(&:amount)
  end

  def daily_expenses_this_month
    expenses = Queries::AccountExpenses
      .new(@account, start_date: beginning_of_month, end_date: end_of_month, include_associations: false)
      .call

    grouped = expenses.group_by { |e| e.transaction_date.day }

    (1..Date.today.day).map do |day|
      daily = grouped[day]&.sum { |e| e.amount.abs } || 0
      { day: day, amount: daily.to_f.round(2) }
    end
  end

  private

  def beginning_of_month
    @beginning_of_month ||= Date.today.beginning_of_month
  end

  def end_of_month
    @end_of_month ||= Date.today.end_of_month
  end
end
