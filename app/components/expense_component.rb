# frozen_string_literal: true

class ExpenseComponent < ApplicationComponent
  attr_reader :expense, :budget, :options
  
  ICONS = {
    expense: 'banknote-arrow-down',
    incoming: 'banknote-arrow-up',
    incoming_transfer: 'arrow-right-left',
    outgoing_transfer: 'arrow-right-left',
  }
  
  ICON_COLOR = {
    expense: '#ff0045',
    incoming: '#05c270',
    incoming_transfer: '#027f53',
    outgoing_transfer: '#027f53',
  }

  def initialize(expense:, **options)
    @expense = expense
    @budget = expense.budget
    @options = options
  end
  
  def icon_color
    ICON_COLOR[expense.type.underscore.to_sym]
  end
  
  def icon
    ICONS[expense.type.underscore.to_sym]
  end
end
