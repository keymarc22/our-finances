class BulkExpensesController < ApplicationController
  before_action :find_budgets, only: :create

  def new
    @expense = Expense.new(user: current_user, transaction_date: Date.current)
  end

  def create
    service = BulkExpenseService.new(params, current_account)
    service.call
    @expenses = service.expenses
    errors = service.errors

    if errors.any?
      flash.now[:error] = errors.join(". ")
      render :new, status: :unprocessable_entity
    else
      flash[:notice] = "#{@expenses.size} expenses created successfully."
      redirect_to expenses_path
    end
  end

  private

  def find_budgets
    @budgets = current_account.budgets.includes(:user)
  end
end