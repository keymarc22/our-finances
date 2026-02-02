class ExpensesController < ApplicationController
  before_action :find_expense, only: %i[edit update destroy]
  before_action :find_budgets, only: %i[update create destroy]
  before_action :from_dashboard, only: %i[new edit update destroy]

  def index
    q = current_account.expenses.includes(:user, :money_account, :budget).ransack(params[:q])
    @pagy, @expenses = pagy(q.result(distinct: true).order(transaction_date: :desc, created_at: :desc),
                            page: params[:page] || 1)
  end

  def new
    @expense = Expense.new(user: current_user, transaction_date: Date.current)
  end
  
  def edit; end

  def create
    @expense = Expense.create(expense_params)

    if @expense.valid? && @expense.persisted?
      flash.now[:notice] = "Expense created successfully."
    else
      flash.now[:error] = @expense.errors.full_messages.to_sentence
    end
  end

  def update
    if @expense.update(expense_params) && @expense.valid?
      # Load dashboard data if request comes from dashboard
      @dashboard = Dashboard.new(current_account) if @from_dashboard
      flash.now[:notice] = "Expense updated successfully."
    else
      flash.now[:error] = @expense.errors.full_messages.to_sentence
    end
  end
  def destroy
    if @expense.destroy
      @dashboard = Dashboard.new(current_account) if @from_dashboard
      flash.now[:notice] = "Expense deleted"
    else
      flash.now[:error] = @expense.errors.full_messages.to_sentence
    end
  end

  private

  def expense_params
    params.require(:expense).permit(
      :amount,
      :description,
      :transaction_type,
      :transaction_date,
      :budget_id,
      :user_id,
      :money_account_id,
      :comment
    ).merge(account_id: current_account.id)
  end

  def find_expense
    @expense = current_account.expenses.find(params[:id])
  end

  def find_budgets
    @budgets = current_account.budgets.includes(:user)
  end
  
  def from_dashboard
    params[:from_dashboard] ||= params.dig(:expense, :from_dashboard)
    @from_dashboard = params[:from_dashboard].present? && params[:from_dashboard] == 'true'
  end
end
