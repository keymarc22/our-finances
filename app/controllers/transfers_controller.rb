class TransfersController < ApplicationController
  before_action :find_transfer, only: :edit
  before_action :find_money_account, only: %i[new edit]
  def new
    @transfer = Transfer.new
  end

  def edit; end

  def create
    @transfer = MoneyAccountTransfer.create(current_user, **transfer_params.to_unsafe_hash.symbolize_keys)
    flash.now[:notice] = "Transfer created."
  rescue => _e
    flash.now[:error] = "Error al realizar la transferencia"
  end

  def update
    data = transfer_params.to_unsafe_hash.symbolize_keys.merge(transfer_id: params[:id])
    @transfer = MoneyAccountTransfer.update(current_user, **data)
    flash.now[:notice] = "Transfer updated."
  rescue => _e
    flash.now[:error] = "Error al actualizar la transferencia"
  end

  def destroy
    @transfer = MoneyAccountTransfer.destroy(current_user, transfer_id: params[:id])
    flash.now[:notice] = "Transfer destroyed."
  rescue => _e
    flash.now[:error] = "Error al eliminar la transferencia"
  end

  private

  def transfer_params
    params.require(:transfer).permit(
      :amount,
      :from_money_account_id,
      :description,
      :to_money_account_id
    ).merge(from_money_account_id: params[:money_account_id])
  end

  def find_transfer
    @transfer = current_account.transfers.find(params[:id])
  end

  def find_money_account
    @money_account = current_account.money_accounts.find(params[:money_account_id])
  end
end
