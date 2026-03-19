class DashboardController < ApplicationController
  def index
    @dashboard = Dashboard.new(current_account)
    @money_accounts = current_account.money_accounts.includes(:incomings, :expenses)
  end
end
