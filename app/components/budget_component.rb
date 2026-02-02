# frozen_string_literal: true

class BudgetComponent < ApplicationComponent
  attr_reader :budget

  def initialize(budget:)
    @budget = budget
  end

  def current_date_range
    @current_date_range ||= Date.current.beginning_of_month.. Date.current.end_of_month
  end
end
