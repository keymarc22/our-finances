class BulkExpenseService
  def initialize(params, current_account)
    @params = params
    @current_account = current_account
    @errors = []
    @expenses = []
  end
  
  def call
    create_expenses
    result
  end
  
  attr_reader :errors, :expenses
  
  private
  
  attr_reader :params, :current_account
  
  def expenses_params
    params.require(:bulk).permit(expenses: [:amount, :description, :budget_id])[:expenses]
  end
  
  def shared_params
    @shared_params ||= params.require(:bulk).permit(:money_account_id, :user_id, :exchange_currency, :exchange_rate, :transaction_date)
  end

  def create_expenses
    ActiveRecord::Base.transaction do
      expenses_params.each_value do |ep|
        expense = Expense.new(
          ep.merge(shared_params).merge(account_id: current_account.id)
        )
        expenses << expense
        unless expense.save
          errors << expense.errors.full_messages.to_sentence
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end
    
    result
  end
  
  def result
    if errors.any?
      { success: false, errors: errors }
    else
      { success: true, expenses: expenses }
    end
  end
end