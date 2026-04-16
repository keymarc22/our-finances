class MonthlyBillPaymentsController < ApplicationController
  before_action :find_bill

  def new
    @payment = @bill.monthly_bill_payments.new
  end

  def create
    @expense = current_account.expenses.new(monthly_bill_payment_params)
    
    ActiveRecord::Base.transaction do
      if @expense.save
        @payment = @bill.monthly_bill_payments.new(
          expense: @expense,
          year: @expense.transaction_date&.year,
          month: @expense.transaction_date&.month,
          paid_at: Time.current
        )

        @payment.save!
        flash.now[:notice] = "#{@bill.name} marked as paid"
        @dashboard = Dashboard.new(current_account)
      else
        raise ActiveRecord::Rollback
      end
    end

    unless @payment&.persisted?
      errors = (@expense&.errors&.full_messages || []) + (@payment&.errors&.full_messages || [])
      flash.now[:error] = errors.to_sentence.presence || "Could not register payment"
    end
  end

  def destroy
    @payment = @bill.monthly_bill_payments.find(params[:id])
    @payment.destroy
    @dashboard = Dashboard.new(current_account)
    flash.now[:notice] = "Payment undone"
  end

  private

  def find_bill
    @bill = current_account.monthly_bills.find(params[:monthly_bill_id])
  end
  
  def monthly_bill_payment_params
    payment_params = params.require(:expense).permit(
      :description, :amount, :money_account_id, :budget_id, :transaction_date, :comment
    ).merge(amount: params[:expense][:amount]&.to_f&.abs, user: current_user, interval: :monthly)

    payment_params[:description] = @bill.name if payment_params[:description].nil?
    payment_params[:transaction_date] = Date.today if payment_params[:transaction_date].nil?
    payment_params
  end
end
