class DashboardController < ApplicationController
  def index
    flash.now[:notice] = "Welcome to your dashboard!"
    @dashboard = Dashboard.new(current_account)
    @money_accounts = current_account.money_accounts.includes(:incomings, :expenses)
  end
end
