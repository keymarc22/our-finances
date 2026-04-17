class MonthlyBillsController < ApplicationController
  before_action :find_bill, only: %i[edit update destroy]

  def index
    @monthly_bills = current_account.monthly_bills.active
      .includes(:money_account, :budget)
      .order(:due_day)
    @total = @monthly_bills.sum(&:amount)
  end

  def new
    @monthly_bill = current_account.monthly_bills.new
  end

  def create
    @monthly_bill = current_account.monthly_bills.new(bill_params)
    if @monthly_bill.save
      flash.now[:notice] = "Bill added successfully"
    else
      flash.now[:error] = @monthly_bill.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @monthly_bill.update(bill_params)
      flash.now[:notice] = "Bill updated successfully"
    else
      flash.now[:error] = @monthly_bill.errors.full_messages.to_sentence
    end
  end

  def destroy
    @monthly_bill.update(active: false)
    flash.now[:notice] = "Bill removed"
  end

  def export
    bills = current_account.monthly_bills.
      active.
      includes(:money_account, :budget).
      order(:due_day)
    
    data = MonthlyBillsExportService.new(bills).call
    send_data data,
      filename: "monthly_bills_#{Date.today}.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment"
  end

  private

  def find_bill
    @monthly_bill = current_account.monthly_bills.find(params[:id])
  end

  def bill_params
    params.require(:monthly_bill).permit(:name, :amount, :due_day, :money_account_id, :budget_id)
  end
end
