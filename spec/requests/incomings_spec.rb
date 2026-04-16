require 'rails_helper'

RSpec.describe "Incomings", type: :request, sign_in: true do
  let(:user)          { @user }
  let(:account)       { user.account }
  let(:money_account) { create(:money_account, name: "Efectivo", account: account, user: user) }
  let(:incoming)      { create(:incoming, money_account: money_account, user: user, account: account, transaction_date: Date.today, amount: 100) }

  describe "GET /money_accounts/:money_account_id/incomings/new" do
    it "returns success" do
      get new_money_account_incoming_path(money_account)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /money_accounts/:money_account_id/incomings/:id/edit" do
    it "returns success" do
      get edit_money_account_incoming_path(money_account, incoming)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /money_accounts/:money_account_id/incomings" do
    it "creates an incoming" do
      expect {
        post money_account_incomings_path(money_account), params: { incoming: {
          amount: 200,
          transaction_date: Date.today,
          money_account_id: money_account.id,
          description: 'new incoming'
        } }
      }.to change(Incoming, :count).by(1)
    end
  end

  describe "PATCH /incomings/:id" do
    it "actualiza el monto del incoming" do
      patch incoming_path(incoming), params: { incoming: { amount: 300 } }, as: :turbo_stream
      expect(incoming.reload.amount_cents).to eq(300_00)
    end

    it "actualiza la descripción del incoming" do
      patch incoming_path(incoming), params: { incoming: { description: "Sueldo actualizado" } }, as: :turbo_stream
      expect(incoming.reload.description).to eq("Sueldo actualizado")
    end

    it "actualiza la fecha del incoming" do
      new_date = Date.today - 5.days
      patch incoming_path(incoming), params: { incoming: { transaction_date: new_date } }, as: :turbo_stream
      expect(incoming.reload.transaction_date.to_date).to eq(new_date)
    end

    it "no actualiza con monto negativo" do
      patch incoming_path(incoming), params: { incoming: { amount: -50 } }, as: :turbo_stream
      expect(incoming.reload.amount_cents).to eq(100_00)
    end

    it "retorna turbo stream" do
      patch incoming_path(incoming), params: { incoming: { amount: 300 } }, as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "no modifica un incoming de otra cuenta" do
      other_account   = create(:account)
      other_user      = create(:user, account: other_account)
      other_ma        = create(:money_account, account: other_account, user: other_user)
      other_incoming  = create(:incoming, money_account: other_ma, user: other_user, account: other_account, amount: 500)

      patch incoming_path(other_incoming), params: { incoming: { amount: 1 } }, as: :turbo_stream
      expect(response).to have_http_status(:not_found)
      expect(other_incoming.reload.amount_cents).to eq(500_00)
    end
  end

  describe "DELETE /incomings/:id" do
    it "elimina el incoming" do
      incoming
      expect {
        delete incoming_path(incoming), as: :turbo_stream
      }.to change(Incoming, :count).by(-1)
    end

    it "retorna turbo stream" do
      delete incoming_path(incoming), as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
