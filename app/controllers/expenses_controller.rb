class ExpensesController < ApplicationController
  before_action :find_expense, only: %i[edit update destroy]
  before_action :find_budgets, only: %i[update create destroy]

  def index
    q = current_account.expenses.includes(:user, :money_account, :budget).ransack(params[:q])
    @pagy, @expenses = pagy(q.result(distinct: true).order(transaction_date: :desc, created_at: :desc),
                            page: params[:page] || 1)
  end

  def new
    @expense = Expense.new(user: current_user, transaction_date: Date.current)
  end

  def create
    @expense = Expense.create(expense_params)

    if @expense.valid?
      flash.now[:notice] = "Gasto creado correctamente."
      load_dashboard_data
    else
      flash.now[:error] = @expense.errors.full_messages.to_sentence
    end
  end

  def update
    if @expense.update(expense_params) && @expense.valid?
      flash.now[:notice] = "Gasto actualizado correctamente."
      if @expense.valid?
        load_dashboard_data
      end
    else
      flash.now[:error] = @expense.errors.full_messages.to_sentence
    end
  end
  def destroy
    if @expense.destroy
      flash.now[:notice] = "Gasto eliminado correctamente."
      respond_to do |format|
        format.turbo_stream
        format.json { render json: { message: "Gasto eliminado correctamente." }, status: :ok }
      end
    else
      flash.now[:error] = @expense.errors.full_messages.to_sentence
      respond_to do |format|
        format.turbo_stream
        format.json { render json: { error: @expense.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  def expense_splits_fields
    @expense = params[:id].present? ? Expense.find(params[:id]) : Expense.new

    if @expense.expense_splits.empty?
      User.find_each do |user|
        @expense.expense_splits.build(user: user, percentage: user.percentage || 50)
      end
    end

    render partial: "/expenses/expense_splits_fields", locals: { expense: @expense }
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
      :comment,
      expense_splits_attributes: %i[user_id percentage expense_id id _destroy]
    ).merge(account_id: current_account.id)
  end

  def find_expense
    @expense = current_account.expenses.find(params[:id])
  end

  def find_budgets
    @budgets = current_account.budgets.includes(:user)
  end

  def load_dashboard_data
    @summary = Dashboard.new(current_account).call
  end
end
