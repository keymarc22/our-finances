class TransfersController < ApplicationController
  before_action :find_transfer, only: :edit
  before_action :find_money_account, only: %i[new edit]
  def new
    @transfer = OutgoingTransfer.new
  end

  def edit; end

  def create
    @transfer = MoneyAccountTransfer.create(current_user, **transfer_params.to_unsafe_hash.symbolize_keys)
    flash.now[:notice] = "Transfer created."
  rescue => _e
    @transfer = OutgoingTransfer.new
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
    outgoing = current_account.outgoing_transfers.find(params[:id])
    @to_money_account = outgoing.transferer_money_account
    @transfer = MoneyAccountTransfer.destroy(current_user, transfer_id: params[:id])
    flash.now[:notice] = "Transfer destroyed."
  rescue => _e
    flash.now[:error] = "Error al eliminar la transferencia"
  end

  private

  def transfer_params
    outgoing_transfer_data = params.permit(outgoing_transfer: [:description, :amount])
                                   .fetch(:outgoing_transfer, ActionController::Parameters.new)
    transfer_data = params.require(:transfer).permit(:to_money_account_id)
    result = transfer_data.merge(outgoing_transfer_data)
                          .merge(from_money_account_id: params[:money_account_id])
    result[:amount] = result[:amount].to_f if result[:amount].present?
    result
  end

  def find_transfer
    @transfer = current_account.outgoing_transfers.find(params[:id])
  end

  def find_money_account
    @money_account = current_account.money_accounts.find(params[:money_account_id])
  end
end
