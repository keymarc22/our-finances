require 'rails_helper'

RSpec.describe "Transfers", type: :request, sign_in: true do
  let(:account)            { @user.account }
  let(:from_money_account) do
    ma = create(:money_account, user: @user, account:)
    create(:incoming, money_account: ma, user: @user, account:, amount_cents: 100_000)
    ma
  end
  let(:to_money_account) { create(:money_account, user: @user, account:) }

  let(:valid_params) do
    {
      outgoing_transfer: { description: "Transferencia de prueba", amount: "50" },
      transfer: { to_money_account_id: to_money_account.id }
    }
  end

  let(:existing_transfer) do
    freeze_time do
      MoneyAccountTransfer.create(
        @user,
        description: "Transferencia existente",
        amount: 30,
        from_money_account_id: from_money_account.id,
        to_money_account_id: to_money_account.id
      )
    end
  end

  describe "GET /money_accounts/:money_account_id/transfers/new" do
    it "retorna éxito" do
      get new_money_account_transfer_path(from_money_account)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /money_accounts/:money_account_id/transfers/:id/edit" do
    it "retorna éxito" do
      get edit_money_account_transfer_path(from_money_account, existing_transfer)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /money_accounts/:money_account_id/transfers" do
    it "crea una transferencia con parámetros válidos" do
      expect {
        post money_account_transfers_path(from_money_account), params: valid_params, as: :turbo_stream
      }.to change(OutgoingTransfer, :count).by(1)
         .and change(IncomingTransfer, :count).by(1)
    end

    it "registra el monto como negativo en la cuenta origen" do
      post money_account_transfers_path(from_money_account), params: valid_params, as: :turbo_stream
      expect(OutgoingTransfer.last.amount_cents).to be < 0
    end

    it "registra el monto como positivo en la cuenta destino" do
      post money_account_transfers_path(from_money_account), params: valid_params, as: :turbo_stream
      expect(IncomingTransfer.last.amount_cents).to be > 0
    end

    it "asigna la descripción a ambas transacciones" do
      post money_account_transfers_path(from_money_account), params: valid_params, as: :turbo_stream
      expect(OutgoingTransfer.last.description).to eq("Transferencia de prueba")
      expect(IncomingTransfer.last.description).to eq("Transferencia de prueba")
    end

    it "responde con turbo stream" do
      post money_account_transfers_path(from_money_account), params: valid_params, as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "no crea la transferencia si los fondos son insuficientes" do
      expect {
        post money_account_transfers_path(from_money_account),
             params: valid_params.merge(outgoing_transfer: { description: "X", amount: "99999" }),
             as: :turbo_stream
      }.not_to change(OutgoingTransfer, :count)
    end

    it "no crea la transferencia si falta la cuenta destino" do
      expect {
        post money_account_transfers_path(from_money_account),
             params: { outgoing_transfer: { description: "X", amount: "50" }, transfer: { to_money_account_id: "" } },
             as: :turbo_stream
      }.not_to change(OutgoingTransfer, :count)
    end
  end

  describe "PATCH /money_accounts/:money_account_id/transfers/:id" do
    it "actualiza la descripción de la transferencia" do
      transfer = existing_transfer
      patch money_account_transfer_path(from_money_account, transfer),
            params: {
              outgoing_transfer: { description: "Transferencia existente", amount: "30" },
              transfer: { to_money_account_id: to_money_account.id }
            },
            as: :turbo_stream
      expect(transfer.reload.description).to eq("Transferencia existente")
    end

    it "retorna turbo stream al actualizar" do
      transfer = existing_transfer
      patch money_account_transfer_path(from_money_account, transfer),
            params: {
              outgoing_transfer: { description: "Nueva desc", amount: "30" },
              transfer: { to_money_account_id: to_money_account.id }
            },
            as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "DELETE /transfers/:id" do
    it "elimina la transferencia saliente y entrante" do
      transfer = existing_transfer
      expect {
        delete transfer_path(transfer), as: :turbo_stream
      }.to change(OutgoingTransfer, :count).by(-1)
         .and change(IncomingTransfer, :count).by(-1)
    end

    it "retorna turbo stream al eliminar" do
      transfer = existing_transfer
      delete transfer_path(transfer), as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end

