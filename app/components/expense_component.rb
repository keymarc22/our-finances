# frozen_string_literal: true

class ExpenseComponent < ApplicationComponent
  attr_reader :expense, :budget, :options
  
  def initialize(expense:, options: {})
    @expense = expense
    @budget = expense.budget
    @options = options
  end
end
